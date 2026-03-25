import Foundation
import HTTPTypes
import ScoreCore
import ScoreRouter
import Testing

@testable import ScoreRuntime

private struct RuntimeHomePage: Page {
    static let path = "/"

    var body: some Node {
        Heading(.one) { Text { "Runtime Home" } }
    }
}

private let runtimeMetadata = SiteMetadata(
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
    var metadata: (any Metadata)? { runtimeMetadata }
    var controllers: [any Controller] { [RuntimeController()] }
    var outputDirectory: String

    init() { outputDirectory = "" }
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }
}

private struct RuntimeErrorPage: ErrorPage {
    var context: ErrorContext

    init(context: ErrorContext) {
        self.context = context
    }

    var body: some Node {
        Heading(.one) { Text { "Error \(context.statusCode)" } }
    }
}

private struct RuntimeAppWithErrorPage: Application {
    var pages: [any Page] { [RuntimeHomePage()] }
    var metadata: (any Metadata)? { runtimeMetadata }
    var controllers: [any Controller] { [RuntimeController()] }
    var outputDirectory: String

    init() { outputDirectory = "" }
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }

    var errorPage: (any ErrorPage.Type)? { RuntimeErrorPage.self }
}

private func makeHandler(
    errorPageType: (any ErrorPage.Type)? = nil
) throws -> (RequestHandler, String) {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-handler-test-\(UUID().uuidString)")
        .path

    let app: any Application
    if errorPageType != nil {
        app = RuntimeAppWithErrorPage(outputDirectory: tempDir)
    } else {
        app = RuntimeApp(outputDirectory: tempDir)
    }

    try StaticSiteEmitter.emit(application: app)

    let handler = RequestHandler(
        outputDirectory: tempDir,
        routeTable: RouteTable(app)
    )
    return (handler, tempDir)
}

private func performRequest(
    method: HTTPRequest.Method,
    uri: String,
    body: Data? = nil,
    errorPage: (any ErrorPage.Type)? = nil
) async throws -> Response {
    let (handler, tempDir) = try makeHandler(errorPageType: errorPage)
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let request = HTTPRequest(method: method, scheme: nil, authority: nil, path: uri)
    return await handler.process(request: request, body: body)
}

@Test func requestHandlerServesStaticPagesForGetRequests() async throws {
    let response = try await performRequest(method: .get, uri: "/?debug=1")

    #expect(response.status == .ok)
    #expect(response.headers["content-type"] == "text/html; charset=utf-8")
    let body = String(data: response.body, encoding: .utf8) ?? ""
    #expect(body.contains("Runtime Home</h1>"))
    #expect(body.contains("<title>Runtime Site</title>"))
}

@Test func requestHandlerInvokesControllerHandlers() async throws {
    let response = try await performRequest(method: .get, uri: "/api/echo/value-42")

    #expect(response.status == .ok)
    #expect(response.headers["content-type"] == "text/plain; charset=utf-8")
    #expect(String(data: response.body, encoding: .utf8) == "value-42")
}

@Test func requestHandlerUsesFallbackForUnknownHTTPMethods() async throws {
    let response = try await performRequest(method: HTTPRequest.Method("TRACE")!, uri: "/api/echo/fallback")

    #expect(response.status == .methodNotAllowed)
    #expect(String(data: response.body, encoding: .utf8) == "Method Not Allowed")
}

@Test func requestHandlerReturnsInternalServerErrorWhenControllerThrows() async throws {
    let response = try await performRequest(method: .get, uri: "/api/boom")

    #expect(response.status == .internalServerError)
    #expect(response.headers["content-type"] == "text/html; charset=utf-8")
    let body = String(data: response.body, encoding: .utf8) ?? ""
    #expect(body.contains("Score Development Error"))
}

@Test func requestHandlerReturnsPlainOkForRoutesWithoutPageOrHandler() async throws {
    let response = try await performRequest(method: .get, uri: "/api/noop")

    #expect(response.status == .ok)
    #expect(response.headers["content-type"] == "text/plain")
    #expect(String(data: response.body, encoding: .utf8) == "OK")
}

@Test func requestHandlerReturnsNotFoundForUnknownPaths() async throws {
    let response = try await performRequest(method: .get, uri: "/missing")

    #expect(response.status == .notFound)
    #expect(String(data: response.body, encoding: .utf8) == "Not Found")
}

@Test func requestHandlerReturnsMethodNotAllowedWithAllowHeader() async throws {
    let response = try await performRequest(method: .delete, uri: "/api/echo/value-42")

    #expect(response.status == .methodNotAllowed)
    #expect(response.headers["Allow"] == "GET, POST")
    #expect(String(data: response.body, encoding: .utf8) == "Method Not Allowed")
}

@Test func requestHandlerPassesQueryParametersToHandler() async throws {
    let response = try await performRequest(method: .get, uri: "/api/query?name=Alice")

    #expect(response.status == .ok)
    #expect(String(data: response.body, encoding: .utf8) == "Alice")
}

@Test func requestHandlerPassesRequestBodyToHandler() async throws {
    let response = try await performRequest(
        method: .post,
        uri: "/api/body",
        body: Data("{\"key\":\"value\"}".utf8)
    )

    #expect(response.status == .ok)
    #expect(String(data: response.body, encoding: .utf8) == "{\"key\":\"value\"}")
}

@Test func requestHandlerRespectsResponseStatusAndHeaders() async throws {
    let response = try await performRequest(method: .post, uri: "/api/status")

    #expect(response.status == .created)
    #expect(response.headers["x-custom"] == "yes")
    #expect(String(data: response.body, encoding: .utf8) == "created")
}

@Test func requestHandlerServesCustomErrorPageFor404() async throws {
    let response = try await performRequest(
        method: .get,
        uri: "/no-such-page",
        errorPage: RuntimeErrorPage.self
    )

    #expect(response.status == .notFound)
    #expect(response.headers["content-type"] == "text/html; charset=utf-8")
    let body = String(data: response.body, encoding: .utf8) ?? ""
    #expect(body.contains("Error 404"))
}

@Test func requestHandlerFallsBackToPlainTextWithoutErrorPage() async throws {
    let response = try await performRequest(
        method: .get,
        uri: "/no-such-page"
    )

    #expect(response.status == .notFound)
    #expect(String(data: response.body, encoding: .utf8) == "Not Found")
}
