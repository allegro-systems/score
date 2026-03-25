import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#colorTokens` macro.
///
/// Generates static `ColorToken` properties for each string argument.
/// Must be used inside an `extension ColorToken { }` block.
///
/// ```swift
/// extension ColorToken {
///     #colorTokens("bg", "score", "stage")
///     // expands to:
///     // static let bg = ColorToken("bg")
///     // static let score = ColorToken("score")
///     // static let stage = ColorToken("stage")
/// }
/// ```
public struct ColorTokensMacro: DeclarationMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let names = node.arguments.compactMap { argument -> String? in
            argument.expression.as(StringLiteralExprSyntax.self)?
                .segments.first.flatMap { segment -> String? in
                    segment.as(StringSegmentSyntax.self)?.content.text
                }
        }

        return names.map { name in
            "static let \(raw: name) = ColorToken(\"\(raw: name)\")"
        }
    }
}
