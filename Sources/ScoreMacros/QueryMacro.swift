import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Query` attached macro.
///
/// Given a stored property declaration like:
/// ```swift
/// @Query("/api/items") var items: [Item]
/// ```
///
/// The macro transforms the property and generates peers:
/// ```swift
/// var items: [Item] {
///     get { _queryStorage_items }
///     set { _queryStorage_items = newValue }
/// }
/// private var _queryStorage_items: [Item] = []
/// let _query_items = QueryDescriptor(name: "items", endpoint: "/api/items")
/// var $items: QueryProjection { QueryProjection(name: "items") }
/// ```
///
/// Type-safe variant using a Controller type:
/// ```swift
/// @Query(ItemsController.self) var items: [Item]
/// ```
///
/// Generates:
/// ```swift
/// let _query_items = QueryDescriptor(name: "items", endpoint: ItemsController().base)
/// ```
///
/// Type-safe variant using an Endpoint:
/// ```swift
/// @Query(CommentController.forPost) var comments: [Comment]
/// ```
///
/// Generates:
/// ```swift
/// let _query_comments = QueryDescriptor(name: "comments", endpoint: CommentController.forPost.path)
/// ```
public struct QueryMacro: AccessorMacro, PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
            let binding = varDecl.bindings.first
        else {
            throw QueryMacroError.notAStoredProperty
        }

        let name = binding.pattern.trimmedDescription

        return [
            """
            get { _queryStorage_\(raw: name) }
            """,
            """
            set { _queryStorage_\(raw: name) = newValue }
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
            throw QueryMacroError.notAStoredProperty
        }

        let name = binding.pattern.trimmedDescription

        let typeAnnotation: String
        if let explicitType = binding.typeAnnotation?.type.trimmedDescription {
            typeAnnotation = ": \(explicitType)"
        } else {
            typeAnnotation = ""
        }

        let args = extractArguments(from: node)

        var peers: [DeclSyntax] = []

        // Backing storage
        peers.append(
            """
            private var _queryStorage_\(raw: name)\(raw: typeAnnotation) = []
            """)

        // QueryDescriptor — endpoint from string literal, Controller().base, or Endpoint.path
        let endpointExpr: String
        if let controllerType = args.controllerType {
            endpointExpr = "\(controllerType)().base"
        } else if let expression = args.endpointExpression {
            endpointExpr = "\(expression).path"
        } else {
            endpointExpr = "\"\(args.endpoint)\""
        }

        var descriptorArgs = "name: \"\(name)\", endpoint: \(endpointExpr)"
        if let poll = args.pollInterval {
            descriptorArgs += ", pollInterval: \(poll)"
        }
        if let sync = args.syncMode {
            descriptorArgs += ", syncMode: .\(sync)"
        }
        peers.append(
            """
            let _query_\(raw: name) = QueryDescriptor(\(raw: descriptorArgs))
            """)

        // QueryProjection
        peers.append(
            """
            var $\(raw: name): QueryProjection { QueryProjection(name: \(literal: name)) }
            """)

        return peers
    }

    private struct QueryArguments {
        var endpoint: String = ""
        var controllerType: String?
        /// A non-literal expression that evaluates to an `Endpoint` value (e.g. `CommentController.forPost`).
        var endpointExpression: String?
        var pollInterval: Int?
        var syncMode: String?
    }

    private static func extractArguments(from node: AttributeSyntax) -> QueryArguments {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return QueryArguments()
        }

        var result = QueryArguments()

        for (index, argument) in arguments.enumerated() {
            if index == 0 {
                // First argument: either a string endpoint or Controller.self
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    result.endpoint = stringLiteral.segments.compactMap { segment -> String? in
                        segment.as(StringSegmentSyntax.self)?.content.text
                    }.joined()
                } else if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
                    let base = memberAccess.base
                {
                    if memberAccess.declName.baseName.text == "self" {
                        // SomeController.self → extract "SomeController"
                        result.controllerType = base.trimmedDescription
                    } else {
                        // SomeController.forPost → Endpoint expression, append .path
                        result.endpointExpression = argument.expression.trimmedDescription
                    }
                } else {
                    // Any other expression (e.g. function call returning Endpoint)
                    result.endpointExpression = argument.expression.trimmedDescription
                }
            } else if argument.label?.text == "poll" {
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    result.pollInterval = Int(intLiteral.literal.text)
                }
            } else if argument.label?.text == "sync" {
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    result.syncMode = memberAccess.declName.baseName.text
                }
            }
        }

        return result
    }
}

enum QueryMacroError: Error, CustomStringConvertible {
    case notAStoredProperty

    var description: String {
        switch self {
        case .notAStoredProperty:
            return "@Query can only be applied to stored properties"
        }
    }
}
