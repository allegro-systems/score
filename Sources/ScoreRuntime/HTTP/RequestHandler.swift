import Foundation
import HTTPTypes
import NIOCore
import NIOHTTP1
import ScoreCore
import ScoreRouter

/// A NIO channel handler that serves pre-built static files from the output
/// directory and dispatches controller routes dynamically.
///
/// Page routes, CSS, JavaScript, and assets are all served from disk after
/// ``StaticSiteEmitter`` writes them during startup. Only controller routes
/// defined via ``Controller`` are handled dynamically at request time.
public final class RequestHandler: ChannelInboundHandler, Sendable {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private let outputDirectory: String
    private let routeTable: RouteTable

    /// Creates a request handler that serves static files and dispatches
    /// controller routes.
    ///
    /// - Parameters:
    ///   - outputDirectory: The directory containing pre-built static files.
    ///   - routeTable: The route table for resolving controller routes.
    public init(
        outputDirectory: String,
        routeTable: RouteTable
    ) {
        self.outputDirectory = outputDirectory
        self.routeTable = routeTable
    }

    private final class RequestState: @unchecked Sendable {
        var head: HTTPRequestHead?
        var body: ByteBuffer?

        init() {}
    }

    private let state = RequestState()

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let head):
            state.head = head
            state.body = nil
        case .body(var buffer):
            if state.body == nil {
                state.body = buffer
            } else {
                state.body?.writeBuffer(&buffer)
            }
        case .end:
            guard let head = state.head else { return }
            let bodyData: Data?
            if let buffer = state.body {
                bodyData = Data(buffer.readableBytesView)
            } else {
                bodyData = nil
            }
            handleRequest(head: head, body: bodyData, context: context)
        }
    }

    private func handleRequest(
        head: HTTPRequestHead,
        body: Data?,
        context: ChannelHandlerContext
    ) {
        let eventLoop = context.eventLoop
        let promise = eventLoop.makePromise(of: Void.self)
        nonisolated(unsafe) let capturedContext = context
        promise.completeWithTask {
            let response = await self.processRequest(head: head, body: body)
            eventLoop.execute {
                self.writeResponse(response, context: capturedContext)
            }
        }
    }

    private func processRequest(head: HTTPRequestHead, body: Data?) async -> Response {
        let uri = head.uri
        let path = uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? uri

        if let response = serveStaticFile(path: path) {
            return response
        }

        guard let method = mapMethod(head.method) else {
            return Response.text("Method Not Allowed", status: .methodNotAllowed)
        }

        do {
            let resolved = try routeTable.resolve(method: method, path: path)

            guard let handler = resolved.handler else {
                var response = Response.text("OK")
                response.headers["content-type"] = "text/plain"
                return response
            }

            let queryParams = RequestContext.parseQuery(uri)
            var nioHeaders: [String: String] = [:]
            for (name, value) in head.headers {
                if nioHeaders[name] == nil {
                    nioHeaders[name] = value
                }
            }

            let requestContext = RequestContext(
                method: method,
                path: path,
                headers: nioHeaders,
                pathParameters: resolved.parameters,
                queryParameters: queryParams,
                body: body
            )

            let result = try await handler(requestContext)
            if let response = result as? Response {
                return response
            }
            return Response.text("OK")

        } catch let error as RoutingError {
            switch error {
            case .notFound:
                return serveErrorPage(statusCode: 404, message: "Not Found")
            case .methodNotAllowed(_, let allowed):
                let allowHeader = allowed.map(\.rawValue).joined(separator: ", ")
                var response = Response.text("Method Not Allowed", status: .methodNotAllowed)
                response.headers["Allow"] = allowHeader
                return response
            }
        } catch {
            let environment = Environment.current
            if environment == .development {
                let html = ErrorOverlay.render(
                    error,
                    path: path,
                    environment: environment
                )
                return Response.html(html, status: .internalServerError)
            }
            return serveErrorPage(statusCode: 500, message: "Internal Server Error")
        }
    }

    /// Attempts to serve a static file from the output directory.
    ///
    /// Tries the following in order:
    /// 1. Exact file match (for CSS, JS, assets, etc.)
    /// 2. Path + `.html` (for page routes like `/about` → `about.html`)
    /// 3. `index.html` for the root path
    private func serveStaticFile(path: String) -> Response? {
        let fm = FileManager.default

        if path == "/" {
            return serveFile(at: "\(outputDirectory)/index.html", fm: fm)
        }

        let relativePath = String(path.dropFirst())
        let directPath = "\(outputDirectory)/\(relativePath)"
        if fm.fileExists(atPath: directPath) {
            return serveFile(at: directPath, fm: fm)
        }

        let htmlPath = "\(outputDirectory)/\(relativePath).html"
        if fm.fileExists(atPath: htmlPath) {
            return serveFile(at: htmlPath, fm: fm)
        }

        return nil
    }

    private func serveFile(at path: String, fm: FileManager) -> Response? {
        guard let data = fm.contents(atPath: path) else { return nil }
        let ext = (path as NSString).pathExtension
        let contentType = StaticFileHandler.mimeType(for: ext)
        return Response(
            status: .ok,
            headers: ["content-type": contentType],
            body: data
        )
    }

    private func serveErrorPage(statusCode: Int, message: String) -> Response {
        let status = HTTPResponse.Status(code: statusCode)
        let errorPath = "\(outputDirectory)/\(statusCode).html"
        if let data = FileManager.default.contents(atPath: errorPath) {
            return Response(
                status: status,
                headers: ["content-type": "text/html; charset=utf-8"],
                body: data
            )
        }
        return Response.text(message, status: status)
    }

    private func writeResponse(_ response: Response, context: ChannelHandlerContext) {
        let status = mapStatus(response.status)
        var headers = HTTPHeaders()
        for (key, value) in response.headers {
            headers.add(name: key, value: value)
        }

        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: response.body.count)
        buffer.writeBytes(response.body)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)

        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func mapMethod(_ method: NIOHTTP1.HTTPMethod) -> HTTPRequest.Method? {
        switch method {
        case .GET: return .get
        case .POST: return .post
        case .PUT: return .put
        case .PATCH: return .patch
        case .DELETE: return .delete
        case .HEAD: return .head
        case .OPTIONS: return .options
        default: return nil
        }
    }

    private func mapStatus(_ status: HTTPResponse.Status) -> HTTPResponseStatus {
        HTTPResponseStatus(statusCode: status.code)
    }
}
