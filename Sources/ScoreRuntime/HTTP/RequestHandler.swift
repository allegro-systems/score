import Foundation
import HTTPTypes
import NIOCore
import NIOHTTP1
import ScoreCore
import ScoreRouter

/// A NIO channel handler that processes HTTP requests through the Score runtime.
public final class RequestHandler: ChannelInboundHandler, Sendable {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private let routeTable: RouteTable
    private let pages: [String: any Page]
    private let metadata: (any Metadata)?
    private let theme: (any Theme)?

    /// Creates a request handler with the given configuration.
    public init(
        routeTable: RouteTable,
        pages: [String: any Page],
        metadata: (any Metadata)?,
        theme: (any Theme)?
    ) {
        self.routeTable = routeTable
        self.pages = pages
        self.metadata = metadata
        self.theme = theme
    }

    // MARK: - State

    private final class RequestState: @unchecked Sendable {
        var head: HTTPRequestHead?
        var body: ByteBuffer?

        init() {}
    }

    private let state = RequestState()

    // MARK: - ChannelInboundHandler

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
        // Safety: context is only used inside eventLoop.execute, which runs on the
        // same event loop that owns the context. nonisolated(unsafe) silences the
        // Sendable diagnostic without introducing actual concurrency risk.
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

        // Serve external CSS files
        if path == "/global.css" {
            let css = theme.map { ThemeCSSEmitter.emit($0) } ?? ""
            return Response.css(css)
        }
        if path.hasPrefix("/styles/") && path.hasSuffix(".css") {
            return serveScopedCSS(for: path)
        }

        // Serve external JavaScript files
        if path == "/score.js" {
            return Response.javascript(JSEmitter.clientRuntime)
        }
        if path.hasPrefix("/scripts/") && path.hasSuffix(".js") {
            return servePageScript(for: path)
        }

        // Map NIO method to HTTPTypes method
        guard let method = mapMethod(head.method) else {
            return Response.text("Method Not Allowed", status: .methodNotAllowed)
        }

        do {
            let resolved = try routeTable.resolve(method: method, path: path)

            if resolved.isPage {
                // Render the page
                if let page = pages[resolved.pattern] {
                    let cssName = Self.cssFileName(for: resolved.pattern)

                    // Determine script links for this page
                    let jsResult = JSEmitter.emitPageScript(page: page)
                    var scriptLinks: [String] = []
                    if !jsResult.pageJS.isEmpty {
                        if jsResult.needsRuntime {
                            scriptLinks.append("/score.js")
                        }
                        scriptLinks.append("/scripts/\(cssName).js")
                    }

                    let result = PageRenderer.render(
                        page: page,
                        metadata: metadata,
                        theme: theme,
                        cssLinks: ["/global.css", "/styles/\(cssName).css"],
                        scriptLinks: scriptLinks
                    )
                    return Response.html(result.html)
                }
                return Response.text("OK", status: .ok)
            }

            // Controller route
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
                return Response.text("Not Found", status: .notFound)
            case .methodNotAllowed(_, let allowed):
                let allowHeader = allowed.map(\.rawValue).joined(separator: ", ")
                var response = Response.text("Method Not Allowed", status: .methodNotAllowed)
                response.headers["Allow"] = allowHeader
                return response
            }
        } catch {
            let html = ErrorOverlay.render(
                error,
                path: path,
                environment: .development
            )
            return Response.html(html, status: .internalServerError)
        }
    }

    /// Serves scoped component CSS for a page by rendering it and extracting its CSS.
    private func serveScopedCSS(for path: String) -> Response {
        // /styles/home.css → "home"
        let fileName = String(path.dropFirst("/styles/".count).dropLast(".css".count))

        // Find the page whose CSS file name matches
        for (pattern, page) in pages {
            if Self.cssFileName(for: pattern) == fileName {
                let result = PageRenderer.render(
                    page: page,
                    metadata: metadata,
                    theme: theme
                )
                return Response.css(result.componentCSS)
            }
        }
        return Response.text("Not Found", status: .notFound)
    }

    /// Serves page-specific JavaScript by rendering the page and extracting its JS.
    private func servePageScript(for path: String) -> Response {
        // /scripts/home.js → "home"
        let fileName = String(path.dropFirst("/scripts/".count).dropLast(".js".count))

        for (pattern, page) in pages {
            if Self.cssFileName(for: pattern) == fileName {
                let result = PageRenderer.render(
                    page: page,
                    metadata: metadata,
                    theme: theme
                )
                if result.pageJS.isEmpty {
                    return Response.text("Not Found", status: .notFound)
                }
                return Response.javascript(result.pageJS)
            }
        }
        return Response.text("Not Found", status: .notFound)
    }

    /// Derives a CSS file name from a page path.
    ///
    /// - `/` → `"home"`
    /// - `/about` → `"about"`
    /// - `/docs/score` → `"docs-score"`
    static func cssFileName(for pagePath: String) -> String {
        if pagePath == "/" { return "home" }
        let trimmed = pagePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.replacingOccurrences(of: "/", with: "-")
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
