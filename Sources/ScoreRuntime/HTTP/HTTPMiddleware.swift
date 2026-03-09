/// A middleware that wraps request handling with cross-cutting concerns.
///
/// `HTTPMiddleware` follows the standard middleware pattern: it receives a
/// request context and a `next` function, and can transform the request,
/// short-circuit the response, or modify the response on the way out.
public struct HTTPMiddleware: Sendable {

    /// The middleware handler closure.
    public let handler:
        @Sendable (
            RequestContext,
            @Sendable (RequestContext) async throws -> Response
        ) async throws -> Response

    /// Creates a middleware with the given handler.
    public init(
        handler:
            @escaping @Sendable (
                RequestContext,
                @Sendable (RequestContext) async throws -> Response
            ) async throws -> Response
    ) {
        self.handler = handler
    }

    /// Composes an array of middleware around a terminal handler.
    ///
    /// Middleware are applied outermost-first: the first middleware in the array
    /// wraps the second, which wraps the third, and so on down to the handler.
    public static func compose(
        _ middlewares: [HTTPMiddleware],
        handler: @escaping @Sendable (RequestContext) async throws -> Response
    ) -> @Sendable (RequestContext) async throws -> Response {
        var composed: @Sendable (RequestContext) async throws -> Response = handler
        for middleware in middlewares.reversed() {
            let next = composed
            let mw = middleware
            composed = { request in
                try await mw.handler(request, next)
            }
        }
        return composed
    }
}
