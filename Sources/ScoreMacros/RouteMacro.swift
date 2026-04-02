import SwiftSyntax
import SwiftSyntaxMacros

/// Marker macro — generates no code.
///
/// `@Route` exists solely so the ``ControllerMacro`` can discover annotated
/// handler functions and extract their path and HTTP method.
public struct RouteMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
