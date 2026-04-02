import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Theme` macro.
///
/// When applied to a struct, this macro adds `Theme` protocol conformance.
/// The `score dev` / `score build` CLI commands handle generating
/// `ColorToken` static properties for custom color role keys via
/// ``ThemeCodegen`` — no manual `#colorTokens(...)` extension is needed.
///
/// ```swift
/// @Theme
/// struct AppTheme {
///     var extraColorRoles: [String: ColorToken] {
///         ["elevated": .oklch(0.96, 0.004, 240)]
///     }
/// }
/// ```
public struct ThemeMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw ThemeMacroError.notAStruct
        }

        if protocols.isEmpty { return [] }

        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): Theme {}
            """

        guard let ext = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [ext]
    }
}

enum ThemeMacroError: Error, CustomStringConvertible {
    case notAStruct

    var description: String {
        switch self {
        case .notAStruct:
            return "@Theme can only be applied to structs"
        }
    }
}
