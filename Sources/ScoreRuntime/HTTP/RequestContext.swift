import Foundation
import HTTPTypes

/// A lightweight request context passed to route handlers and middleware.
public struct RequestContext: Sendable {

    /// The HTTP method of the request.
    public let method: HTTPRequest.Method

    /// The request path (without query string).
    public let path: String

    /// Request headers as a simple string-keyed dictionary.
    ///
    /// When multiple values exist for the same header, only the first is stored.
    public var headers: [String: String]

    /// Extracted path parameters (e.g. `["id": "42"]`).
    public var pathParameters: [String: String]

    /// Parsed query parameters.
    public var queryParameters: [String: String]

    /// The raw request body, if any.
    public var body: Data?

    /// Creates a request context.
    public init(
        method: HTTPRequest.Method,
        path: String,
        headers: [String: String] = [:],
        pathParameters: [String: String] = [:],
        queryParameters: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
        self.body = body
    }

    /// Parses query parameters from a URI string.
    ///
    /// Returns a dictionary of key-value pairs. Keys without `=` get an empty value.
    /// First occurrence wins for duplicate keys. Percent-decoding is applied.
    public static func parseQuery(_ uri: String) -> [String: String] {
        guard let qIndex = uri.firstIndex(of: "?") else { return [:] }
        let queryString = uri[uri.index(after: qIndex)...]
        var result: [String: String] = [:]
        for pair in queryString.split(separator: "&", omittingEmptySubsequences: true) {
            let parts = pair.split(separator: "=", maxSplits: 1)
            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            let value: String
            if parts.count > 1 {
                value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            } else {
                value = ""
            }
            if result[key] == nil {
                result[key] = value
            }
        }
        return result
    }
}
