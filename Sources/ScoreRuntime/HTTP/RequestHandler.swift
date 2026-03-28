import Foundation
import HTTPTypes
import Logging
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
    private let maxBodySize: Int
    private let loggingMiddleware = RequestLoggingMiddleware()
    private let metricsMiddleware = RequestMetricsMiddleware()
    private let tracingMiddleware = RequestTracingMiddleware()

    /// Creates a request handler that serves static files and dispatches
    /// controller routes.
    ///
    /// - Parameters:
    ///   - outputDirectory: The directory containing pre-built static files.
    ///   - routeTable: The route table for resolving controller routes.
    /// - Parameters:
    ///   - outputDirectory: The directory containing pre-built static files.
    ///   - routeTable: The route table for resolving controller routes.
    ///   - maxBodySize: Maximum allowed request body size in bytes (default: 10 MB).
    public init(
        outputDirectory: String,
        routeTable: RouteTable,
        maxBodySize: Int = 10 * 1024 * 1024
    ) {
        self.outputDirectory = outputDirectory
        self.routeTable = routeTable
        self.maxBodySize = maxBodySize
    }

    // MARK: - State

    /// Accumulates request parts on a single NIO event loop.
    /// Not Sendable — only accessed within its channel pipeline.
    private struct RequestState {
        var head: HTTPRequestHead?
        var body: ByteBuffer?
    }

    private nonisolated(unsafe) var state = RequestState()

    private static let supportedMethods: Set<HTTPRequest.Method> = [
        .get, .post, .put, .patch, .delete, .head, .options,
    ]

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
            if let size = state.body?.readableBytes, size > maxBodySize {
                let response = Response.text("Request body too large", status: .init(code: 413))
                writeResponse(response, context: context)
                context.close(promise: nil)
                return
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
            guard let method = self.mapMethod(head.method) else {
                let response = Response.text("Method Not Allowed", status: .methodNotAllowed)
                eventLoop.execute {
                    self.writeResponse(response, context: capturedContext)
                }
                return
            }

            var request = HTTPRequest(method: method, scheme: "http", authority: "localhost", path: head.uri)
            for (name, value) in head.headers {
                if let fieldName = HTTPField.Name(name) {
                    request.headerFields.append(HTTPField(name: fieldName, value: value))
                }
            }

            let response = await self.process(request: request, body: body)

            // Touch heartbeat file so stage-manager can track activity
            if let alivePath = ProcessInfo.processInfo.environment["STAGE_ALIVE_PATH"] {
                FileManager.default.createFile(atPath: alivePath, contents: nil)
            }

            eventLoop.execute {
                self.writeResponse(response, context: capturedContext)
            }
        }
    }

    // MARK: - Request Logging

    private func logged(
        method: HTTPRequest.Method,
        path: String,
        startTime: Date,
        response: Response
    ) -> Response {
        let duration = Date().timeIntervalSince(startTime)
        let result = loggingMiddleware.handle(method: method, path: path, response: response, duration: duration)
        metricsMiddleware.record(method: method, path: path, response: response, duration: duration)
        return result
    }

    // MARK: - Request Processing

    /// Processes an HTTP request and returns a response.
    ///
    /// - Parameters:
    ///   - request: The HTTP request metadata and headers.
    ///   - body: The raw request body data, if any.
    /// - Returns: The response to send back to the client.
    func process(request: HTTPRequest, body: Data?) async -> Response {
        let uri = request.path ?? "/"
        let path = uri.split(separator: "?", maxSplits: 1).first.map(String.init) ?? uri
        let method = request.method

        return await tracingMiddleware.withSpan(method: method, path: path) {
            let startTime = Date()

            // Dev tools edit API (development only)
            if path == "/_dev/edit" && method == .post && Environment.current == .development {
                let devResponse = self.handleDevEdit(body: body)
                return self.logged(method: method, path: path, startTime: startTime, response: devResponse)
            }

            if let response = self.serveStaticFile(path: path) {
                return self.logged(method: method, path: path, startTime: startTime, response: response)
            }

            guard Self.supportedMethods.contains(method) else {
                let notAllowed = Response.text("Method Not Allowed", status: .methodNotAllowed)
                return self.logged(method: method, path: path, startTime: startTime, response: notAllowed)
            }

            do {
                let resolved = try self.routeTable.resolve(method: method, path: path)

                guard let handler = resolved.handler else {
                    var response = Response.text("OK")
                    response.headers["content-type"] = "text/plain"
                    return self.logged(method: method, path: path, startTime: startTime, response: response)
                }

                let queryParams = RequestContext.parseQuery(uri)
                var headers: [String: String] = [:]
                for field in request.headerFields {
                    let name = field.name.rawName.lowercased()
                    if headers[name] == nil {
                        headers[name] = field.value
                    }
                }

                let requestContext = RequestContext(
                    method: method,
                    path: path,
                    headers: headers,
                    pathParameters: resolved.parameters,
                    queryParameters: queryParams,
                    body: body
                )

                let result = try await handler(requestContext)
                if let response = result as? Response {
                    return self.logged(method: method, path: path, startTime: startTime, response: response)
                }
                let okResponse = Response.text("OK")
                return self.logged(method: method, path: path, startTime: startTime, response: okResponse)

            } catch let error as RoutingError {
                switch error {
                case .notFound:
                    let notFound = self.serveErrorPage(statusCode: 404, message: "Not Found")
                    return self.logged(method: method, path: path, startTime: startTime, response: notFound)
                case .methodNotAllowed(_, let allowed):
                    let allowHeader = allowed.map(\.rawValue).joined(separator: ", ")
                    var response = Response.text("Method Not Allowed", status: .methodNotAllowed)
                    response.headers["Allow"] = allowHeader
                    return self.logged(method: method, path: path, startTime: startTime, response: response)
                }
            } catch {
                let environment = Environment.current
                if environment == .development {
                    let html = ErrorOverlay.render(
                        error,
                        path: path,
                        environment: environment
                    )
                    let errorResponse = Response.html(html, status: .internalServerError)
                    return self.logged(method: method, path: path, startTime: startTime, response: errorResponse)
                }
                let serverError = self.serveErrorPage(statusCode: 500, message: "Internal Server Error")
                return self.logged(method: method, path: path, startTime: startTime, response: serverError)
            }
        }
    }

    // MARK: - Static File Serving

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

        // Reject path traversal attempts
        guard !relativePath.contains("..") else { return nil }

        let directPath = "\(outputDirectory)/\(relativePath)"
        guard resolvedPathIsWithin(directPath, directory: outputDirectory) else { return nil }
        if let response = serveFile(at: directPath, fm: fm) {
            return response
        }

        let htmlPath = "\(outputDirectory)/\(relativePath).html"
        if let response = serveFile(at: htmlPath, fm: fm) {
            return response
        }

        let indexPath = "\(outputDirectory)/\(relativePath)/index.html"
        if let response = serveFile(at: indexPath, fm: fm) {
            return response
        }

        return nil
    }

    private func resolvedPathIsWithin(_ path: String, directory: String) -> Bool {
        let resolved = (path as NSString).standardizingPath
        let base = (directory as NSString).standardizingPath
        return resolved.hasPrefix(base + "/") || resolved == base
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

    // MARK: - NIO Response Writing

    private func writeResponse(_ response: Response, context: ChannelHandlerContext) {
        let status = HTTPResponseStatus(statusCode: Int(response.status.code))
        var headers = HTTPHeaders()
        for (key, value) in response.headers {
            headers.add(name: key, value: value)
        }
        if !response.body.isEmpty {
            headers.replaceOrAdd(name: "content-length", value: String(response.body.count))
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

    // MARK: - Dev Tools Edit API

    private enum EditAction {
        case text(oldValue: String, newValue: String)
        case style(property: String, value: String)
    }

    private struct EditRequest: Decodable {
        let type: String
        let sourcePath: String
        let oldValue: String?
        let newValue: String?
        let property: String?
        let propertyValue: String?

        func action() -> EditAction? {
            switch type {
            case "text":
                guard let oldValue, let newValue else { return nil }
                return .text(oldValue: oldValue, newValue: newValue)
            case "style":
                guard let property, let propertyValue else { return nil }
                return .style(property: property, value: propertyValue)
            default:
                return nil
            }
        }
    }

    private func handleDevEdit(body: Data?) -> Response {
        guard let body else {
            return Response.text("Missing request body", status: .badRequest)
        }

        guard let request = try? JSONDecoder().decode(EditRequest.self, from: body) else {
            return Response.text("Invalid JSON payload", status: .badRequest)
        }

        guard let action = request.action() else {
            return Response.text("Invalid or incomplete edit request", status: .badRequest)
        }

        let pathParts = request.sourcePath.split(separator: ":", maxSplits: 2)
        guard let filePath = pathParts.first.map(String.init) else {
            return Response.text("Invalid sourcePath", status: .badRequest)
        }

        // Validate the file path stays within the project directory
        let cwd = FileManager.default.currentDirectoryPath
        let resolved = (filePath as NSString).standardizingPath
        guard resolved.hasPrefix(cwd + "/") || resolved == cwd else {
            return Response.text("sourcePath outside project directory", status: .forbidden)
        }

        let lineNumber = pathParts.count > 1 ? Int(pathParts[1]) : nil

        switch action {
        case .text(let oldValue, let newValue):
            return performTextEdit(
                filePath: filePath,
                lineNumber: lineNumber,
                oldValue: oldValue,
                newValue: newValue
            )

        case .style(let property, let value):
            return performStyleEdit(
                filePath: filePath,
                lineNumber: lineNumber,
                property: property,
                value: value
            )
        }
    }

    private func writeFileResponse(content: String, filePath: String) -> Response {
        do {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            return Response(
                status: .ok,
                headers: ["content-type": "application/json"],
                body: Data("{\"ok\":true}".utf8)
            )
        } catch {
            return Response.text("Failed to write file: \(error)", status: .internalServerError)
        }
    }

    private func performTextEdit(
        filePath: String,
        lineNumber: Int?,
        oldValue: String,
        newValue: String
    ) -> Response {
        guard var content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return Response.text("Cannot read file", status: .internalServerError)
        }

        let escapedOld = DevToolsInjector.jsEscape(oldValue)
        let escapedNew = DevToolsInjector.jsEscape(newValue)

        // If we have a line number, try to replace only on that line for precision
        if let line = lineNumber {
            var lines = content.components(separatedBy: "\n")
            let idx = line - 1
            if idx >= 0 && idx < lines.count {
                if lines[idx].contains("\"\(escapedOld)\"") {
                    lines[idx] = lines[idx].replacingOccurrences(
                        of: "\"\(escapedOld)\"",
                        with: "\"\(escapedNew)\""
                    )
                    content = lines.joined(separator: "\n")
                } else if lines[idx].contains(escapedOld) {
                    lines[idx] = lines[idx].replacingOccurrences(of: escapedOld, with: escapedNew)
                    content = lines.joined(separator: "\n")
                } else {
                    // Fall back to global replace
                    content = content.replacingOccurrences(
                        of: "\"\(escapedOld)\"",
                        with: "\"\(escapedNew)\""
                    )
                }
            }
        } else {
            content = content.replacingOccurrences(
                of: "\"\(escapedOld)\"",
                with: "\"\(escapedNew)\""
            )
        }

        return writeFileResponse(content: content, filePath: filePath)
    }

    private func performStyleEdit(
        filePath: String,
        lineNumber: Int?,
        property: String,
        value: String
    ) -> Response {
        guard var content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return Response.text("Cannot read file", status: .internalServerError)
        }

        // Style edits target modifier parameters near the given line
        guard let line = lineNumber else {
            return Response.text("Line number required for style edits", status: .badRequest)
        }

        var lines = content.components(separatedBy: "\n")
        let idx = line - 1
        guard idx >= 0 && idx < lines.count else {
            return Response.text("Line number out of range", status: .badRequest)
        }

        // Search nearby lines for the property in a modifier call
        let searchRange = max(0, idx - 5)...min(lines.count - 1, idx + 5)
        for i in searchRange {
            if let range = lines[i].range(of: "\(property):\\s*[^,)]+", options: .regularExpression) {
                lines[i] = lines[i].replacingCharacters(
                    in: range,
                    with: "\(property): \(value)"
                )
                content = lines.joined(separator: "\n")
                break
            }
        }

        return writeFileResponse(content: content, filePath: filePath)
    }
}
