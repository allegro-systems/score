import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Controller` macro.
///
/// Scans the struct for `@Route`-annotated functions and generates:
/// - `var base: String` from the macro argument
/// - `var routes: [Route]` collecting all handlers
/// - `static var <funcName>: Endpoint` for each route handler
/// - `Controller` conformance via extension
public struct ControllerMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw ControllerMacroError.notAStruct
        }

        // Extract base path from @Controller("/api/posts")
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let firstArg = arguments.first,
            let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self)
        else {
            throw ControllerMacroError.missingBasePath
        }

        let basePath = stringLiteral.segments.compactMap {
            $0.as(StringSegmentSyntax.self)?.content.text
        }.joined()

        // Scan members for @Route functions
        let routeInfos = extractRouteInfos(from: declaration)

        var members: [DeclSyntax] = []

        // var base: String
        members.append(
            """
            var base: String { \(literal: basePath) }
            """)

        // var routes: [Route]
        if routeInfos.isEmpty {
            members.append(
                """
                var routes: [Route] { [] }
                """)
        } else {
            let entries = routeInfos.map { info in
                if info.path == "/" {
                    return "Route(method: \(info.method), handler: \(info.funcName))"
                } else {
                    return "Route(method: \(info.method), path: \(quoted(info.path)), handler: \(info.funcName))"
                }
            }.joined(separator: ",\n            ")

            members.append(
                """
                var routes: [Route] {
                    [
                        \(raw: entries)
                    ]
                }
                """)
        }

        // Static endpoint properties — one per handler function
        for info in routeInfos {
            if info.path == "/" {
                members.append(
                    """
                    static var \(raw: info.funcName): Endpoint { endpoint() }
                    """)
            } else {
                members.append(
                    """
                    static var \(raw: info.funcName): Endpoint { endpoint(\(literal: info.path)) }
                    """)
            }
        }

        return members
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            throw ControllerMacroError.notAStruct
        }

        // Don't add conformance if already present
        if protocols.isEmpty {
            return []
        }

        let extensionDecl: DeclSyntax = """
            extension \(type.trimmed): Controller {}
            """

        guard let ext = extensionDecl.as(ExtensionDeclSyntax.self) else {
            return []
        }

        return [ext]
    }

    // MARK: - Helpers

    private struct RouteInfo {
        let funcName: String
        let path: String
        let method: String
    }

    private static func extractRouteInfos(from declaration: some DeclGroupSyntax) -> [RouteInfo] {
        var infos: [RouteInfo] = []

        for member in declaration.memberBlock.members {
            guard let funcDecl = member.decl.as(FunctionDeclSyntax.self) else { continue }

            // Find @Route attribute
            guard let routeAttr = funcDecl.attributes.first(where: { attr in
                guard let attrSyntax = attr.as(AttributeSyntax.self) else { return false }
                return attrSyntax.attributeName.trimmedDescription == "Route"
            })?.as(AttributeSyntax.self) else { continue }

            let funcName = funcDecl.name.text
            var path = "/"
            var method = ".get"

            if let args = routeAttr.arguments?.as(LabeledExprListSyntax.self) {
                for arg in args {
                    if let label = arg.label?.text {
                        if label == "method" {
                            method = arg.expression.trimmedDescription
                        }
                    } else {
                        // Unlabeled argument = path string
                        if let stringLit = arg.expression.as(StringLiteralExprSyntax.self) {
                            path = stringLit.segments.compactMap {
                                $0.as(StringSegmentSyntax.self)?.content.text
                            }.joined()
                        }
                    }
                }
            }

            infos.append(RouteInfo(funcName: funcName, path: path, method: method))
        }

        return infos
    }

    private static func quoted(_ string: String) -> String {
        "\"\(string)\""
    }
}

enum ControllerMacroError: Error, CustomStringConvertible {
    case notAStruct
    case missingBasePath

    var description: String {
        switch self {
        case .notAStruct:
            return "@Controller can only be applied to structs"
        case .missingBasePath:
            return "@Controller requires a base path string argument"
        }
    }
}
