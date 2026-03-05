import Foundation
import HTTPTypes
import Logging
import NIOCore
import NIOHTTP1
import ScoreCore
import ScoreRouter

/// NIO channel handler that processes HTTP/1.1 requests for the Score server.
///
/// `RequestHandler` accumulates the full request (head + body), resolves
/// incoming requests against a ``RouteTable``, renders pages via
/// ``PageRenderer``, invokes controller handlers with a ``RequestContext``,
/// and produces appropriate HTTP responses including 404 and 405 error pages.
final class RequestHandler: ChannelInboundHandler, Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let routeTable: RouteTable
    private let pages: [String: any Page]
    private let metadata: Metadata?
    private let theme: (any Theme)?
    private let staticDirectory: String?
    private let outputRoot: String?
    private let middlewares: [HTTPMiddleware]
    private let environment: Environment
    private let logger: Logger

    /// In-memory store of source maps keyed by script ID, populated during
    /// page rendering in development mode and served under `/_score/maps/`.
    let sourceMaps: SourceMapStore

    // Request accumulation state. Safe because NIO calls channelRead
    // on the same event loop thread for a given channel.
    nonisolated(unsafe) private var requestHead: HTTPRequestHead?
    nonisolated(unsafe) private var bodyBuffer: ByteBuffer?

    init(
        routeTable: RouteTable,
        pages: [String: any Page],
        metadata: Metadata?,
        theme: (any Theme)?,
        staticDirectory: String? = nil,
        outputRoot: String? = nil,
        middlewares: [HTTPMiddleware] = [],
        environment: Environment = .current,
        logger: Logger = Logger(label: "dev.allegro.score.server")
    ) {
        self.routeTable = routeTable
        self.pages = pages
        self.metadata = metadata
        self.theme = theme
        self.staticDirectory = staticDirectory
        self.outputRoot = outputRoot
        self.middlewares = middlewares
        self.environment = environment
        self.sourceMaps = SourceMapStore()
        self.logger = logger
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)

        switch part {
        case .head(let head):
            requestHead = head
            bodyBuffer = context.channel.allocator.buffer(capacity: 0)

        case .body(var buffer):
            bodyBuffer?.writeBuffer(&buffer)

        case .end:
            guard let head = requestHead else { return }
            let start = ContinuousClock.now
            dispatch(head: head, body: bodyBuffer, context: context, start: start)
            requestHead = nil
            bodyBuffer = nil
        }
    }

    private func dispatch(
        head: HTTPRequestHead,
        body: ByteBuffer?,
        context: ChannelHandlerContext,
        start: ContinuousClock.Instant
    ) {
        let uri = head.uri
        let path = uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? uri
        guard let method = httpMethod(from: head.method) else {
            respond(context: context, status: .methodNotAllowed, contentType: "text/plain", body: "Method Not Allowed")
            logRequest(method: head.method, path: path, status: .methodNotAllowed, start: start)
            return
        }

        // Dev resource serving — /_score/ paths in development mode.
        if environment == .development, path.hasPrefix("/_score/") {
            if let result = serveDevResource(path: path) {
                switch result {
                case .text(let body, let contentType):
                    respond(context: context, status: .ok, contentType: contentType, body: body)
                case .binary(let body, let contentType):
                    respondWithData(context: context, status: .ok, contentType: contentType, body: body)
                }
                logRequest(method: head.method, path: path, status: .ok, start: start)
            } else {
                respond(context: context, status: .notFound, contentType: "text/plain", body: "Not Found")
                logRequest(method: head.method, path: path, status: .notFound, start: start)
            }
            return
        }

        // Static file serving — checked before route resolution.
        if let staticDir = staticDirectory, path.hasPrefix("/static/") {
            let relativePath = String(path.dropFirst("/static/".count))
            if let (data, contentType) = StaticFileHandler.serve(relativePath: relativePath, from: staticDir) {
                respondWithData(context: context, status: .ok, contentType: contentType, body: data)
                logRequest(method: head.method, path: path, status: .ok, start: start)
            } else {
                respond(context: context, status: .notFound, contentType: "text/plain", body: "Not Found")
                logRequest(method: head.method, path: path, status: .notFound, start: start)
            }
            return
        }

        // Serve pre-rendered static output (HTML pages, CSS, JS).
        if let root = outputRoot {
            if let (data, contentType) = serveFromOutput(path: path, root: root) {
                respondWithData(context: context, status: .ok, contentType: contentType, body: data)
                logRequest(method: head.method, path: path, status: .ok, start: start)
                return
            }
        }

        do {
            let resolved = try routeTable.resolve(method: method, path: path)

            if resolved.isPage, let page = pages[resolved.pattern] {
                // Fall back to live rendering when static output is unavailable.
                let html: String
                do {
                    let result = try PageRenderer.renderWithDevTools(
                        page: page,
                        metadata: metadata,
                        theme: theme,
                        environment: environment
                    )
                    html = result.html
                    if let id = result.scriptID, let map = result.sourceMap {
                        sourceMaps.store(id: id, json: map)
                    }
                } catch {
                    if environment == .development {
                        let overlay = ErrorOverlay.render(error, path: path, environment: environment)
                        respond(context: context, status: .internalServerError, contentType: "text/html; charset=utf-8", body: overlay)
                        logRequest(method: head.method, path: path, status: .internalServerError, start: start)
                        return
                    }
                    throw error
                }
                respond(context: context, status: .ok, contentType: "text/html; charset=utf-8", body: html)
                logRequest(method: head.method, path: path, status: .ok, start: start)
            } else if let handler = resolved.handler {
                let queryParameters = RequestContext.parseQuery(uri)
                let headers = Dictionary(
                    head.headers.map { ($0.name.lowercased(), $0.value) },
                    uniquingKeysWith: { first, _ in first }
                )
                var bodyData: Data?
                if var buf = body, buf.readableBytes > 0 {
                    if let bytes = buf.readBytes(length: buf.readableBytes) {
                        bodyData = Data(bytes)
                    }
                }
                let requestContext = RequestContext(
                    method: method,
                    path: path,
                    pathParameters: resolved.parameters,
                    queryParameters: queryParameters,
                    headers: headers,
                    body: bodyData
                )

                let eventLoop = context.eventLoop
                let promise = eventLoop.makePromise(of: Response.self)

                let mws = self.middlewares
                promise.completeWithTask {
                    let baseHandler: @Sendable (RequestContext) async throws -> Response = { ctx in
                        let result = try await handler(ctx as any Sendable)
                        if let response = result as? Response {
                            return response
                        }
                        return Response.text(String(describing: result))
                    }
                    let pipeline = HTTPMiddleware.compose(mws, handler: baseHandler)
                    return try await pipeline(requestContext)
                }

                nonisolated(unsafe) let ctx = context
                let startCopy = start
                let pathCopy = path
                let methodCopy = head.method
                promise.futureResult.whenComplete { [self] result in
                    switch result {
                    case .success(let response):
                        self.respondWithResponse(context: ctx, response: response)
                        self.logRequest(method: methodCopy, path: pathCopy, status: self.nioStatus(from: response.status), start: startCopy)
                    case .failure:
                        self.respond(context: ctx, status: .internalServerError, contentType: "text/plain", body: "Internal Server Error")
                        self.logRequest(method: methodCopy, path: pathCopy, status: .internalServerError, start: startCopy)
                    }
                }
                return
            } else {
                respond(context: context, status: .ok, contentType: "text/plain", body: "OK")
                logRequest(method: head.method, path: path, status: .ok, start: start)
            }
        } catch let error as RoutingError {
            switch error {
            case .notFound:
                respond(context: context, status: .notFound, contentType: "text/plain", body: "Not Found")
                logRequest(method: head.method, path: path, status: .notFound, start: start)
            case .methodNotAllowed(_, let allowed):
                let allowHeader = allowed.map(\.rawValue).joined(separator: ", ")
                respond(
                    context: context,
                    status: .methodNotAllowed,
                    contentType: "text/plain",
                    body: "Method Not Allowed",
                    extraHeaders: [("Allow", allowHeader)]
                )
                logRequest(method: head.method, path: path, status: .methodNotAllowed, start: start)
            }
        } catch {
            respond(context: context, status: .internalServerError, contentType: "text/plain", body: "Internal Server Error")
            logRequest(method: head.method, path: path, status: .internalServerError, start: start)
        }
    }

    // MARK: - Response Helpers

    private func respond(
        context: ChannelHandlerContext,
        status: HTTPResponseStatus,
        contentType: String,
        body: String,
        extraHeaders: [(String, String)] = []
    ) {
        let bodyData = ByteBuffer(string: body)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: String(bodyData.readableBytes))
        for (name, value) in extraHeaders {
            headers.add(name: name, value: value)
        }

        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(bodyData))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func respondWithData(
        context: ChannelHandlerContext,
        status: HTTPResponseStatus,
        contentType: String,
        body: Data
    ) {
        var buffer = context.channel.allocator.buffer(capacity: body.count)
        buffer.writeBytes(body)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: contentType)
        headers.add(name: "Content-Length", value: String(body.count))

        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func respondWithResponse(context: ChannelHandlerContext, response: Response) {
        let status = nioStatus(from: response.status)
        var buffer = context.channel.allocator.buffer(capacity: response.body.count)
        buffer.writeBytes(response.body)

        var headers = HTTPHeaders()
        for (name, value) in response.headers {
            headers.add(name: name, value: value)
        }
        headers.replaceOrAdd(name: "Content-Length", value: String(response.body.count))

        let head = HTTPResponseHead(version: .http1_1, status: status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }

    // MARK: - Logging

    private func logRequest(
        method: NIOHTTP1.HTTPMethod,
        path: String,
        status: HTTPResponseStatus,
        start: ContinuousClock.Instant
    ) {
        let duration = ContinuousClock.now - start
        logger.info("\(method) \(path) \(status.code) \(duration)")
    }

    // MARK: - Conversions

    private func httpMethod(from nioMethod: NIOHTTP1.HTTPMethod) -> HTTPRequest.Method? {
        switch nioMethod {
        case .GET: return .get
        case .POST: return .post
        case .PUT: return .put
        case .DELETE: return .delete
        case .PATCH: return .patch
        case .HEAD: return .head
        case .OPTIONS: return .options
        default: return nil
        }
    }

    private func nioStatus(from status: HTTPResponse.Status) -> HTTPResponseStatus {
        HTTPResponseStatus(statusCode: status.code)
    }

    // MARK: - Static Output

    private func serveFromOutput(path: String, root: String) -> (Data, String)? {
        let rootURL = URL(fileURLWithPath: root).standardized

        // Direct file match (e.g. /as-global.css → root/as-global.css).
        let directPath = rootURL.appendingPathComponent(path).standardized.path
        guard directPath.hasPrefix(rootURL.path) else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: directPath, isDirectory: &isDir),
            !isDir.boolValue,
            let data = FileManager.default.contents(atPath: directPath)
        {
            let ext = (directPath as NSString).pathExtension.lowercased()
            return (data, StaticFileHandler.mimeType(for: ext))
        }

        // Directory-style page route (e.g. /about → root/about/index.html).
        let indexPath = rootURL.appendingPathComponent(path == "/" ? "/index.html" : path + "/index.html").standardized.path
        guard indexPath.hasPrefix(rootURL.path) else { return nil }
        if FileManager.default.fileExists(atPath: indexPath, isDirectory: &isDir),
            !isDir.boolValue,
            let data = FileManager.default.contents(atPath: indexPath)
        {
            return (data, "text/html; charset=utf-8")
        }

        return nil
    }

    // MARK: - Dev Resources

    private enum DevResource {
        case text(body: String, contentType: String)
        case binary(body: Data, contentType: String)
    }

    private func serveDevResource(path: String) -> DevResource? {
        switch path {
        case "/_score/signal-polyfill.js":
            return serveBundledJS(resource: "signal-polyfill")

        case "/_score/score-runtime.js":
            return serveBundledJS(resource: "score-runtime")

        case "/_score/score-devtools.js":
            return serveBundledJS(resource: "score-devtools")

        case "/_score/score-editor.js":
            return serveBundledJS(resource: "score-editor")

        case "/_score/score-lsp.js":
            return serveBundledJS(resource: "score-lsp")

        case "/_score/web-tree-sitter.js":
            return serveBundledJS(resource: "web-tree-sitter")

        case "/_score/tree-sitter.wasm":
            return serveBundledWASM(resource: "tree-sitter")

        case "/_score/tree-sitter-swift.wasm":
            return serveBundledWASM(resource: "tree-sitter-swift")

        case "/_score/tree-sitter-typescript.wasm":
            return serveBundledWASM(resource: "tree-sitter-typescript")

        case "/_score/tree-sitter-c.wasm":
            return serveBundledWASM(resource: "tree-sitter-c")

        case "/_score/tree-sitter-bash.wasm":
            return serveBundledWASM(resource: "tree-sitter-bash")

        default:
            // Source map requests: /_score/maps/<scriptID>.js.map
            if path.hasPrefix("/_score/maps/"), path.hasSuffix(".js.map") {
                let filename = String(path.dropFirst("/_score/maps/".count))
                let scriptID = String(filename.dropLast(".js.map".count))
                if let json = sourceMaps.get(id: scriptID) {
                    return .text(body: json, contentType: "application/json")
                }
            }
            return nil
        }
    }

    private func serveBundledJS(resource: String) -> DevResource? {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "js"),
            let contents = try? String(contentsOf: url, encoding: .utf8)
        else { return nil }
        return .text(
            body: contents,
            contentType: "application/javascript; charset=utf-8"
        )
    }

    private func serveBundledWASM(resource: String) -> DevResource? {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "wasm"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return .binary(body: data, contentType: "application/wasm")
    }
}

/// Thread-safe in-memory store for source map JSON strings.
final class SourceMapStore: Sendable {
    private let storage = _SourceMapStorage()

    func store(id: String, json: String) {
        storage.set(id: id, json: json)
    }

    func get(id: String) -> String? {
        storage.get(id: id)
    }
}

/// Uses `nonisolated(unsafe)` storage protected by a lock.
private final class _SourceMapStorage: Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var maps: [String: String] = [:]

    func set(id: String, json: String) {
        lock.lock()
        defer { lock.unlock() }
        maps[id] = json
    }

    func get(id: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return maps[id]
    }
}
