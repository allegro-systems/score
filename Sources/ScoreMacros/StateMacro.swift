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
        let persistedKey = extractPersisted(from: node)

        let typeAnnotation: String
        if let explicitType = binding.typeAnnotation?.type.trimmedDescription {
            typeAnnotation = ": \(explicitType)"
        } else {
            typeAnnotation = ""
        }

        var peers: [DeclSyntax] = []

        // Detect grouped state: initializer is a struct constructor call (e.g., ItemForm())
        // In that case, generate GroupedStateDescriptor + GroupedStateProjection
        // instead of StateDescriptor + ReactiveTextNode.
        let isGroupedState = isStructConstructorCall(binding)

        if isGroupedState {
            let typeName = extractConstructorTypeName(binding)

            peers.append(
                """
                private var _stateStorage_\(raw: name)\(raw: typeAnnotation) = \(raw: initializer)
                """)

            peers.append(
                """
                let _grouped_\(raw: name) = GroupedStateDescriptor(name: \(literal: name), fields: \(raw: typeName).jsFields)
                """)

            peers.append(
                """
                var $\(raw: name): GroupedStateProjection { GroupedStateProjection(name: \(literal: name)) }
                """)
        } else {
            let jsValue = formatJSLiteral(initializer, binding: binding)

            peers.append(
                """
                private var _stateStorage_\(raw: name)\(raw: typeAnnotation) = \(raw: initializer)
                """)

            if let key = persistedKey {
                if key.isTheme {
                    peers.append(
                        """
                        let _state_\(raw: name) = StateDescriptor(name: \(literal: name), jsInitialValue: \(literal: jsValue), storageKey: \(literal: key.storageKey), isTheme: true)
                        """)
                } else {
                    peers.append(
                        """
                        let _state_\(raw: name) = StateDescriptor(name: \(literal: name), jsInitialValue: \(literal: jsValue), storageKey: \(literal: key.storageKey))
                        """)
                }
            } else {
                peers.append(
                    """
                    let _state_\(raw: name) = StateDescriptor(name: \(literal: name), jsInitialValue: \(literal: jsValue))
                    """)
            }

            peers.append(
                """
                var $\(raw: name): ReactiveTextNode {
                    ReactiveTextNode(name: \(literal: name), text: \"\\(\(raw: name))\")
                }
                """)
        }

        return peers
    }

    struct PersistedKey {
        let storageKey: String
        let isTheme: Bool
    }

    private static func extractPersisted(from node: AttributeSyntax) -> PersistedKey? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        for argument in arguments {
            guard argument.label?.text == "persisted" else { continue }

            if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
                memberAccess.declName.baseName.text == "theme"
            {
                return PersistedKey(storageKey: "as-theme", isTheme: true)
            }

            if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                let content = stringLiteral.segments.compactMap { segment -> String? in
                    segment.as(StringSegmentSyntax.self)?.content.text
                }.joined()
                return PersistedKey(storageKey: content, isTheme: false)
            }
        }
        return nil
    }

    /// Returns `true` when the initializer is a struct constructor call
    /// (e.g., `ItemForm()` or `ItemForm(title: "")`) as opposed to a
    /// primitive literal like `0`, `""`, or `true`.
    private static func isStructConstructorCall(_ binding: PatternBindingSyntax) -> Bool {
        guard let initExpr = binding.initializer?.value else { return false }
        guard let call = initExpr.as(FunctionCallExprSyntax.self) else { return false }

        // The callee must be a simple identifier starting with uppercase (type name)
        if let ident = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = ident.baseName.text
            return name.first?.isUppercase == true
        }
        return false
    }

    /// Extracts the type name from a struct constructor call initializer.
    private static func extractConstructorTypeName(_ binding: PatternBindingSyntax) -> String {
        guard let initExpr = binding.initializer?.value,
            let call = initExpr.as(FunctionCallExprSyntax.self),
            let ident = call.calledExpression.as(DeclReferenceExprSyntax.self)
        else { return "Unknown" }
        return ident.baseName.text
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
