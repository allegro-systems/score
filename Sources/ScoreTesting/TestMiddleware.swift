import ScoreRuntime

/// Helpers for testing middleware pipelines.
///
/// ### Example
///
/// ```swift
/// let response = try await TestMiddleware.run(
///     middlewares: [.cors(), .compression()],
///     request: TestRequest.get("/api/data"),
///     handler: { _ in Response.text("OK") }
/// )
/// #expect(response.headers["access-control-allow-origin"] == "*")
/// ```
public struct TestMiddleware: Sendable {

    /// Runs a middleware pipeline with the given request and terminal handler.
    public static func run(
        middlewares: [HTTPMiddleware],
        request: RequestContext,
        handler: @escaping @Sendable (RequestContext) async throws -> Response
    ) async throws -> Response {
        let pipeline = HTTPMiddleware.compose(middlewares, handler: handler)
        return try await pipeline(request)
    }
}
