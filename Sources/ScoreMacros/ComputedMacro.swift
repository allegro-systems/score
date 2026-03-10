import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Computed` attached peer macro.
///
/// Given a computed property declaration like:
/// ```swift
/// @Computed var label: String { liked ? "Active" : "Idle" }
/// ```
///
/// The macro auto-generates a peer `ComputedDescriptor` with JavaScript
/// translated from the Swift getter body:
/// ```swift
/// let _computed_label = ComputedDescriptor(
///     name: "label",
///     body: "(liked.get() ? \"Active\" : \"Idle\")"
/// )
/// ```
///
/// When a `js:` argument is provided, it overrides the auto-generated body.
///
/// The `JSEmitter` discovers these descriptors via Mirror reflection
/// to emit client-side JavaScript computed signals.
public struct ComputedMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw ComputedMacroError.notAComputedProperty
        }

        guard let binding = varDecl.bindings.first else {
            throw ComputedMacroError.notAComputedProperty
        }

        let name = binding.pattern.trimmedDescription
        let jsBody =
            extractJSBody(from: node)
            ?? translateComputedBody(binding, in: context)

        var peers: [DeclSyntax] = []

        if let jsBody, !jsBody.isEmpty {
            peers.append(
                """
                let _computed_\(raw: name) = ComputedDescriptor(name: \(literal: name), body: \(literal: jsBody))
                """)
        } else {
            peers.append(
                """
                let _computed_\(raw: name) = ComputedDescriptor(name: \(literal: name))
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

    private static func extractJSBody(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        for argument in arguments {
            guard argument.label?.text == "js" else { continue }
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

    private static func translateComputedBody(
        _ binding: PatternBindingSyntax,
        in context: some MacroExpansionContext
    ) -> String? {
        guard let accessor = binding.accessorBlock else { return nil }

        switch accessor.accessors {
        case .getter(let body):
            let statements = Array(body)
            guard statements.count == 1,
                let item = statements.first
            else { return nil }

            let expr: ExprSyntax
            if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
                expr = exprStmt.expression
            } else if let returnStmt = item.item.as(ReturnStmtSyntax.self),
                let returnExpr = returnStmt.expression
            {
                expr = returnExpr
            } else if let directExpr = ExprSyntax(item.item) {
                expr = directExpr
            } else {
                return nil
            }

            let result = SwiftToJSTranslator.translateValue(expr)
            if result == nil {
                context.diagnose(
                    .init(
                        node: Syntax(expr),
                        message: TranslationWarning(
                            "@Computed: use @Computed(js:) for expressions the auto-translator cannot handle"
                        )
                    ))
            }
            return result
        case .accessors:
            return nil
        }
    }
}

private struct TranslationWarning: DiagnosticMessage {
    let message: String
    var diagnosticID: MessageID { MessageID(domain: "ComputedMacro", id: "translationFailure") }
    var severity: DiagnosticSeverity { .warning }
    init(_ message: String) { self.message = message }
}

enum ComputedMacroError: Error, CustomStringConvertible {
    case notAComputedProperty

    var description: String {
        switch self {
        case .notAComputedProperty:
            return "@Computed can only be applied to computed properties"
        }
    }
}
