import Foundation
import HTTPTypes

/// An HTTP response produced by route handlers and middleware.
public struct Response: Sendable {

    /// The HTTP status code.
    public var status: HTTPResponse.Status

    /// Response headers as a simple string-keyed dictionary.
    public var headers: [String: String]

    /// The response body data.
    public var body: Data

    /// Creates a response with the given components.
    public init(
        status: HTTPResponse.Status = .ok,
        headers: [String: String] = [:],
        body: Data = Data()
    ) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    /// Creates a plain text response.
    public static func text(_ string: String, status: HTTPResponse.Status = .ok) -> Response {
        Response(
            status: status,
            headers: ["content-type": "text/plain; charset=utf-8"],
            body: Data(string.utf8)
        )
    }

    /// Creates an HTML response.
    public static func html(_ string: String, status: HTTPResponse.Status = .ok) -> Response {
        Response(
            status: status,
            headers: ["content-type": "text/html; charset=utf-8"],
            body: Data(string.utf8)
        )
    }

    /// Creates a JSON response from raw data.
    public static func json(_ data: Data, status: HTTPResponse.Status = .ok) -> Response {
        Response(
            status: status,
            headers: ["content-type": "application/json"],
            body: data
        )
    }

    /// Creates a CSS response.
    public static func css(_ string: String, status: HTTPResponse.Status = .ok) -> Response {
        Response(
            status: status,
            headers: ["content-type": "text/css; charset=utf-8"],
            body: Data(string.utf8)
        )
    }

    /// Creates a JavaScript response.
    public static func javascript(_ string: String, status: HTTPResponse.Status = .ok) -> Response {
        Response(
            status: status,
            headers: ["content-type": "application/javascript; charset=utf-8"],
            body: Data(string.utf8)
        )
    }
}
