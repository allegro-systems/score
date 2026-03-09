import Foundation
import NIOCore
import NIOHTTP1
import HTTPTypes
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
            if var buffer = state.body {
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
        let promise = context.eventLoop.makePromise(of: Void.self)
        promise.completeWithTask {
            let response = await self.processRequest(head: head, body: body)
            self.writeResponse(response, context: context)
        }
    }

    private func processRequest(head: HTTPRequestHead, body: Data?) async -> Response {
        let uri = head.uri
        let path = uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? uri

        // Map NIO method to HTTPTypes method
        guard let method = mapMethod(head.method) else {
            return Response.text("Method Not Allowed", status: .methodNotAllowed)
        }

        do {
            let resolved = try routeTable.resolve(method: method, path: path)

            if resolved.isPage {
                // Render the page
                if let page = pages[resolved.pattern] {
                    let html = PageRenderer.render(
                        page: page,
                        metadata: metadata,
                        theme: theme
                    )
                    return Response.html(html)
                }
                return Response.text("OK", status: .ok)
            }

            // Controller route
            guard let handler = resolved.handler else {
                var resp = Response.text("OK")
                resp.headers["content-type"] = "text/plain"
                return resp
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
                var resp = Response.text("Method Not Allowed", status: .methodNotAllowed)
                resp.headers["Allow"] = allowHeader
                return resp
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
