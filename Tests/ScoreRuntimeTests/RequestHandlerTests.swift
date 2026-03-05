import Foundation
import NIOCore
import NIOEmbedded
import NIOHTTP1
import ScoreCore
import ScoreRouter
import Testing

@testable import ScoreRuntime

// MARK: - Helpers

private struct RuntimeHomePage: Page {
    static let path = "/"

    var body: some Node {
        Heading(.one) { Text(verbatim: "Runtime Home") }
    }
}

private let runtimeMetadata = Metadata(
    site: "Runtime Site",
    description: "Runtime description",
    keywords: ["runtime", "tests"],
    structuredData: ["{\"@type\":\"WebPage\"}"]
)

private struct RuntimeController: Controller {
    let base = "/api"

    var routes: [Route] {
        [
            Route(method: .get, path: "/echo/:value") { (ctx: RequestContext) -> Response in
                let value = ctx.pathParameters["value"] ?? "missing"
                return Response.text(value)
            },
            Route(method: .post, path: "/echo/:value") { (ctx: RequestContext) -> Response in
                let value = ctx.pathParameters["value"] ?? "missing"
                return Response.text(value)
            },
            Route(method: .get, path: "/boom") { (_: RequestContext) -> Response in
                throw RuntimeHandlerError.boom
            },
            Route(method: .get, path: "/noop"),
            Route(method: .get, path: "/query") { (ctx: RequestContext) -> Response in
                let name = ctx.queryParameters["name"] ?? "none"
                return Response.text(name)
            },
            Route(method: .post, path: "/body") { (ctx: RequestContext) -> Response in
                if let body = ctx.body, let text = String(data: body, encoding: .utf8) {
                    return Response.text(text)
                }
                return Response.text("no body")
            },
            Route(method: .post, path: "/status") { (_: RequestContext) -> Response in
                Response(status: .created, headers: ["x-custom": "yes"], body: Data("created".utf8))
            },
        ]
    }
}

private enum RuntimeHandlerError: Error {
    case boom
}

private struct RuntimeApp: Application {
    var pages: [any Page] { [RuntimeHomePage()] }
    var metadata: Metadata? { runtimeMetadata }
    var controllers: [any Controller] { [RuntimeController()] }
}

private struct CapturedResponse {
    let status: HTTPResponseStatus
    let headers: HTTPHeaders
    let body: String
}

private enum ResponseCaptureError: Error {
    case missingPart
    case invalidPart
    case invalidBody
}

private func makeChannel() async -> NIOAsyncTestingChannel {
    let app = RuntimeApp()
    return await NIOAsyncTestingChannel(
        handler: RequestHandler(
            routeTable: RouteTable(app),
            pages: [RuntimeHomePage.path: RuntimeHomePage()],
            metadata: app.metadata,
            theme: nil
        )
    )
}

private func performRequest(
    method: NIOHTTP1.HTTPMethod,
    uri: String,
    body: ByteBuffer? = nil
) async throws -> CapturedResponse {
    let channel = await makeChannel()
    let head = HTTPRequestHead(version: .http1_1, method: method, uri: uri)

    try await channel.writeInbound(HTTPServerRequestPart.head(head))
    if let body = body {
        try await channel.writeInbound(HTTPServerRequestPart.body(body))
    }
    try await channel.writeInbound(HTTPServerRequestPart.end(nil))

    let responseHead = try await readResponsePart(from: channel)
    guard case .head(let head) = responseHead else {
        throw ResponseCaptureError.invalidPart
    }

    let responseBody = try await readResponsePart(from: channel)
    guard case .body(.byteBuffer(var buffer)) = responseBody else {
        throw ResponseCaptureError.invalidBody
    }

    let responseEnd = try await readResponsePart(from: channel)
    guard case .end = responseEnd else {
        throw ResponseCaptureError.invalidPart
    }

    guard let body = buffer.readString(length: buffer.readableBytes) else {
        throw ResponseCaptureError.invalidBody
    }

    return CapturedResponse(status: head.status, headers: head.headers, body: body)
}

private func readResponsePart(from channel: NIOAsyncTestingChannel) async throws -> HTTPServerResponsePart {
    try await channel.waitForOutboundWrite(as: HTTPServerResponsePart.self)
}

@Test func requestHandlerRendersPagesForGetRequests() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/?debug=1")

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.headers["Content-Type"].first == "text/html; charset=utf-8")
    #expect(response.body.contains("Runtime Home</h1>"))
    #expect(response.body.contains("<title>Runtime Site</title>"))
}

@Test func requestHandlerInvokesControllerHandlers() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/api/echo/value-42")

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.headers["Content-Type"].first == "text/plain; charset=utf-8")
    #expect(response.body == "value-42")
}

@Test func requestHandlerUsesFallbackForUnknownHTTPMethods() async throws {
    let response = try await performRequest(
        method: NIOHTTP1.HTTPMethod(rawValue: "TRACE"), uri: "/api/echo/fallback"
    )

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.body == "fallback")
}

@Test func requestHandlerReturnsInternalServerErrorWhenControllerThrows() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/api/boom")

    #expect(response.status == HTTPResponseStatus.internalServerError)
    #expect(response.headers["Content-Type"].first == "text/plain")
    #expect(response.body == "Internal Server Error")
}

@Test func requestHandlerReturnsPlainOkForRoutesWithoutPageOrHandler() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/api/noop")

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.headers["Content-Type"].first == "text/plain")
    #expect(response.body == "OK")
}

@Test func requestHandlerReturnsNotFoundForUnknownPaths() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/missing")

    #expect(response.status == HTTPResponseStatus.notFound)
    #expect(response.body == "Not Found")
}

@Test func requestHandlerReturnsMethodNotAllowedWithAllowHeader() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.DELETE, uri: "/api/echo/value-42")

    #expect(response.status == HTTPResponseStatus.methodNotAllowed)
    #expect(response.headers["Allow"].first == "GET, POST")
    #expect(response.body == "Method Not Allowed")
}

@Test func requestHandlerPassesQueryParametersToHandler() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.GET, uri: "/api/query?name=Alice")

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.body == "Alice")
}

@Test func requestHandlerPassesRequestBodyToHandler() async throws {
    var buffer = ByteBuffer()
    buffer.writeString("{\"key\":\"value\"}")
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.POST, uri: "/api/body", body: buffer)

    #expect(response.status == HTTPResponseStatus.ok)
    #expect(response.body == "{\"key\":\"value\"}")
}

@Test func requestHandlerRespectsResponseStatusAndHeaders() async throws {
    let response = try await performRequest(method: NIOHTTP1.HTTPMethod.POST, uri: "/api/status")

    #expect(response.status == HTTPResponseStatus.created)
    #expect(response.headers["x-custom"].first == "yes")
    #expect(response.body == "created")
}
