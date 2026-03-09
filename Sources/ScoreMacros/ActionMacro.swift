import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Action` attached peer macro.
///
/// Given a function declaration like:
/// ```swift
/// @Action func toggle() {
///     liked.toggle()
///     count += liked ? 1 : -1
/// }
/// ```
///
/// The macro generates a peer `ActionDescriptor` stored property:
/// ```swift
/// let _action_toggle = ActionDescriptor(name: "toggle")
/// ```
///
/// The `JSEmitter` discovers these descriptors via Mirror reflection
/// to emit client-side JavaScript action functions.
public struct ActionMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw ActionMacroError.notAFunction
        }

        let name = funcDecl.name.text

        let descriptor: DeclSyntax = """
            let _action_\(raw: name) = ActionDescriptor(name: \(literal: name))
            """

        return [descriptor]
    }
}

enum ActionMacroError: Error, CustomStringConvertible {
    case notAFunction

    var description: String {
        switch self {
        case .notAFunction:
            return "@Action can only be applied to functions"
        }
    }
}
