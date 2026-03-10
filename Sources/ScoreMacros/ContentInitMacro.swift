import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@ContentInit` attached member macro.
///
/// Given a struct like:
/// ```swift
/// @ContentInit
/// struct MyLayout<Content: Node>: Component {
///     let content: Content
///     var body: some Node { content }
/// }
/// ```
///
/// The macro generates:
/// ```swift
/// init(@NodeBuilder content: () -> Content) {
///     self.content = content()
/// }
/// ```
public struct ContentInitMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ContentInitMacroError.notAStruct
        }

        let members = structDecl.memberBlock.members
        guard members.contains(where: { isContentProperty($0) }) else {
            throw ContentInitMacroError.noContentProperty
        }

        let initDecl: DeclSyntax = """
            init(@NodeBuilder content: () -> Content) {
                self.content = content()
            }
            """
        return [initDecl]
    }

    private static func isContentProperty(_ member: MemberBlockItemSyntax) -> Bool {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else { return false }
        for binding in variable.bindings {
            guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            if pattern.identifier.text == "content" {
                return true
            }
        }
        return false
    }
}

enum ContentInitMacroError: Error, CustomStringConvertible {
    case notAStruct
    case noContentProperty

    var description: String {
        switch self {
        case .notAStruct:
            return "@ContentInit can only be applied to structs"
        case .noContentProperty:
            return "@ContentInit requires a 'content' property"
        }
    }
}
