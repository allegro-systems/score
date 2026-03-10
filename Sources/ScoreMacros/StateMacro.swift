import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@State` attached macro.
///
/// Given a stored property declaration like:
/// ```swift
/// @State var count = 0
/// ```
///
/// The macro transforms the property and generates peers:
/// ```swift
/// var count: Int {
///     get { _stateStorage_count }
///     set { _stateStorage_count = newValue }
/// }
/// private var _stateStorage_count: Int = 0
/// let _state_count = StateDescriptor(
///     name: "count", jsInitialValue: "0"
/// )
/// var $count: ReactiveTextNode {
///     ReactiveTextNode(name: "count", text: "\(count)")
/// }
/// ```
public struct StateMacro: AccessorMacro, PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first
        else {
            throw StateMacroError.notAStoredProperty
        }

        let name = binding.pattern.trimmedDescription

        return [
            """
            get { _stateStorage_\(raw: name) }
            """,
            """
            set { _stateStorage_\(raw: name) = newValue }
            """,
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first
        else {
            throw StateMacroError.notAStoredProperty
        }

        let name = binding.pattern.trimmedDescription
        let initializer = binding.initializer?.value.trimmedDescription ?? "nil"
        let storageKey = extractPersisted(from: node) ?? ""

        let typeAnnotation: String
        if let explicitType = binding.typeAnnotation?.type.trimmedDescription {
            typeAnnotation = ": \(explicitType)"
        } else {
            typeAnnotation = ""
        }

        let jsValue = formatJSLiteral(initializer, binding: binding)

        var peers: [DeclSyntax] = []

        peers.append(
            """
            private var _stateStorage_\(raw: name)\(raw: typeAnnotation) = \(raw: initializer)
            """)

        if storageKey.isEmpty {
            peers.append(
                """
                let _state_\(raw: name) = StateDescriptor(name: \(literal: name), jsInitialValue: \(literal: jsValue))
                """)
        } else {
            peers.append(
                """
                let _state_\(raw: name) = StateDescriptor(name: \(literal: name), jsInitialValue: \(literal: jsValue), storageKey: \(literal: storageKey))
                """)
        }

        peers.append(
            """
            var $\(raw: name): ReactiveTextNode {
                ReactiveTextNode(name: \(literal: name), text: \"\\(\(raw: name))\")
            }
            """)

        return peers
    }

    private static func extractPersisted(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        for argument in arguments {
            guard argument.label?.text == "persisted" else { continue }
            guard let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) else {
                continue
            }
            let content = stringLiteral.segments.compactMap { segment -> String? in
                segment.as(StringSegmentSyntax.self)?.content.text
            }.joined()
            return content
        }
        return nil
    }

    private static func formatJSLiteral(_ initializer: String, binding: PatternBindingSyntax) -> String {
        guard let initExpr = binding.initializer?.value else { return "undefined" }

        if initExpr.is(IntegerLiteralExprSyntax.self) {
            return initializer
        }
        if initExpr.is(FloatLiteralExprSyntax.self) {
            return initializer
        }
        if let boolLiteral = initExpr.as(BooleanLiteralExprSyntax.self) {
            return boolLiteral.literal.text
        }
        if let stringLiteral = initExpr.as(StringLiteralExprSyntax.self) {
            let content = stringLiteral.segments.compactMap { segment -> String? in
                segment.as(StringSegmentSyntax.self)?.content.text
            }.joined()
            return "\"\(content)\""
        }
        if initExpr.is(PrefixOperatorExprSyntax.self) {
            return initializer
        }

        return "undefined"
    }
}

enum StateMacroError: Error, CustomStringConvertible {
    case notAStoredProperty

    var description: String {
        switch self {
        case .notAStoredProperty:
            return "@State can only be applied to stored properties"
        }
    }
}
