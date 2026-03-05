import Foundation
import HTTPTypes

/// The context for an incoming HTTP request, passed to controller handlers.
///
/// `RequestContext` bundles path parameters, query parameters, headers, and
/// the request body into a single value that handlers receive.
public struct RequestContext: Sendable {

    /// The HTTP method of the request.
    public let method: HTTPRequest.Method

    /// The URL path (without query string).
    public let path: String

    /// Parameters extracted from dynamic path segments (e.g. `":id"`).
    public let pathParameters: [String: String]

    /// Query string parameters. First value wins for duplicate keys.
    public let queryParameters: [String: String]

    /// Request headers with lowercased names. First value wins for duplicate names.
    public let headers: [String: String]

    /// The raw request body, or `nil` for bodyless methods.
    public let body: Data?

    /// Creates a request context.
    public init(
        method: HTTPRequest.Method,
        path: String,
        pathParameters: [String: String] = [:],
        queryParameters: [String: String] = [:],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
        self.headers = headers
        self.body = body
    }

    /// Parses query parameters from a URI string.
    static func parseQuery(_ uri: String) -> [String: String] {
        guard let qIndex = uri.firstIndex(of: "?") else { return [:] }
        let queryString = uri[uri.index(after: qIndex)...]
        var result: [String: String] = [:]
        for pair in queryString.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            guard let key = kv.first else { continue }
            let value = kv.count > 1 ? String(kv[1]) : ""
            let rawKey = String(key).replacingOccurrences(of: "+", with: " ")
            let rawValue = value.replacingOccurrences(of: "+", with: " ")
            let decodedKey = rawKey.removingPercentEncoding ?? rawKey
            let decodedValue = rawValue.removingPercentEncoding ?? rawValue
            if result[decodedKey] == nil {
                result[decodedKey] = decodedValue
            }
        }
        return result
    }
}
