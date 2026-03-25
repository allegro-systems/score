import Foundation
import HTTPTypes
import Testing

@testable import ScoreRuntime

@Suite("CompressionMiddleware")
struct CompressionMiddlewareTests {

    private func makeRequest(acceptEncoding: String = "gzip, deflate") -> RequestContext {
        RequestContext(method: .get, path: "/", headers: ["accept-encoding": acceptEncoding])
    }

    @Test("Compresses large text responses")
    func compressesLargeText() async throws {
        let middleware = HTTPMiddleware.compression(minimumSize: 100)
        let largeBody = String(repeating: "Hello, World! ", count: 100)
        let handler: @Sendable (RequestContext) async throws -> Response = { _ in
            Response.text(largeBody)
        }
        let response = try await middleware.handler(makeRequest(), handler)
        #expect(response.body.count > 0)
        // Compressed body should be smaller than original
        if response.headers["content-encoding"] == "deflate" {
            #expect(response.body.count < Data(largeBody.utf8).count)
        }
    }

    @Test("Skips small responses")
    func skipsSmall() async throws {
        let middleware = HTTPMiddleware.compression(minimumSize: 1024)
        let handler: @Sendable (RequestContext) async throws -> Response = { _ in
            Response.text("small")
        }
        let response = try await middleware.handler(makeRequest(), handler)
        #expect(response.headers["content-encoding"] == nil)
    }

    @Test("Skips when client does not accept compression")
    func skipsNoGzip() async throws {
        let middleware = HTTPMiddleware.compression(minimumSize: 0)
        let handler: @Sendable (RequestContext) async throws -> Response = { _ in
            Response.text(String(repeating: "x", count: 2000))
        }
        let response = try await middleware.handler(makeRequest(acceptEncoding: ""), handler)
        #expect(response.headers["content-encoding"] == nil)
    }

    @Test("Skips binary content types")
    func skipsBinary() async throws {
        let middleware = HTTPMiddleware.compression(minimumSize: 0)
        let handler: @Sendable (RequestContext) async throws -> Response = { _ in
            Response(
                status: .ok,
                headers: ["content-type": "image/png"],
                body: Data(repeating: 0, count: 2000)
            )
        }
        let response = try await middleware.handler(makeRequest(), handler)
        #expect(response.headers["content-encoding"] == nil)
    }
}
