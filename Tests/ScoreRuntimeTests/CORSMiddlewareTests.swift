import HTTPTypes
import Testing

@testable import ScoreRuntime

@Suite("CORSMiddleware")
struct CORSMiddlewareTests {

    private func makeRequest(
        method: HTTPRequest.Method = .get,
        path: String = "/api/data",
        headers: [String: String] = ["origin": "https://example.com"]
    ) -> RequestContext {
        RequestContext(method: method, path: path, headers: headers)
    }

    private func okHandler(_ request: RequestContext) async throws -> Response {
        Response.text("OK")
    }

    @Test("Permissive CORS adds wildcard origin")
    func permissiveCORSAddsWildcard() async throws {
        let middleware = HTTPMiddleware.cors(.permissive)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-allow-origin"] == "*")
    }

    @Test("Specific origin is reflected when matched")
    func specificOriginReflected() async throws {
        let config = CORSConfiguration(allowedOrigins: ["https://example.com"])
        let middleware = HTTPMiddleware.cors(config)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-allow-origin"] == "https://example.com")
    }

    @Test("Unmatched origin gets no CORS headers")
    func unmatchedOriginNoCORS() async throws {
        let config = CORSConfiguration(allowedOrigins: ["https://other.com"])
        let middleware = HTTPMiddleware.cors(config)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-allow-origin"] == nil)
    }

    @Test("Preflight returns 204 with CORS headers")
    func preflightReturns204() async throws {
        let middleware = HTTPMiddleware.cors(.permissive)
        let request = makeRequest(method: .options)
        let response = try await middleware.handler(request, okHandler)
        #expect(response.status == .noContent)
        #expect(response.headers["access-control-allow-origin"] == "*")
        #expect(response.headers["access-control-allow-methods"] != nil)
    }

    @Test("Credentials config reflects specific origin")
    func credentialsReflectsOrigin() async throws {
        let config = CORSConfiguration(allowedOrigins: ["*"], allowCredentials: true)
        let middleware = HTTPMiddleware.cors(config)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-allow-origin"] == "https://example.com")
        #expect(response.headers["access-control-allow-credentials"] == "true")
    }

    @Test("Max age is set on preflight")
    func maxAgeOnPreflight() async throws {
        let config = CORSConfiguration(maxAge: 3600)
        let middleware = HTTPMiddleware.cors(config)
        let request = makeRequest(method: .options)
        let response = try await middleware.handler(request, okHandler)
        #expect(response.headers["access-control-max-age"] == "3600")
    }

    @Test("Exposed headers are included")
    func exposedHeaders() async throws {
        let config = CORSConfiguration(exposedHeaders: ["X-Request-Id"])
        let middleware = HTTPMiddleware.cors(config)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-expose-headers"] == "X-Request-Id")
    }

    @Test("Strict config blocks all origins")
    func strictBlocksAll() async throws {
        let middleware = HTTPMiddleware.cors(.strict)
        let response = try await middleware.handler(makeRequest(), okHandler)
        #expect(response.headers["access-control-allow-origin"] == nil)
    }
}
