import HTTPTypes

/// An error raised when route resolution fails.
///
/// `RoutingError` distinguishes between a path that has no matching route
/// at all (404) and a path that exists but does not accept the requested
/// HTTP method (405). Each case carries enough context for the runtime to
/// build an appropriate HTTP error response.
public enum RoutingError: Error, Sendable {

    /// No route matches the requested path.
    ///
    /// The runtime should respond with HTTP 404 Not Found.
    ///
    /// - Parameter path: The request path that could not be matched.
    case notFound(path: String)

    /// The path matches one or more routes, but none accept the requested method.
    ///
    /// The runtime should respond with HTTP 405 Method Not Allowed and include
    /// an `Allow` header listing `allowed`.
    ///
    /// - Parameters:
    ///   - path: The request path that matched.
    ///   - allowed: The HTTP methods that the path does accept.
    case methodNotAllowed(path: String, allowed: [HTTPRequest.Method])

    /// The HTTP response status appropriate for this error.
    public var status: HTTPResponse.Status {
        switch self {
        case .notFound: .notFound
        case .methodNotAllowed: .methodNotAllowed
        }
    }
}

extension RoutingError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .notFound(let path):
            return "No route matches path '\(path)'"
        case .methodNotAllowed(let path, let allowed):
            let methods = allowed.map(\.rawValue).joined(separator: ", ")
            return "Method not allowed for path '\(path)' (allowed: \(methods))"
        }
    }
}
