import Foundation
import HTTPTypes

/// An HTTP response produced by route handlers and middleware.
public struct Response: Sendable {

    /// The HTTP status code.
    public var status: HTTPResponse.Status

    /// Response headers supporting multiple values per name (e.g. Set-Cookie).
    public var headers: ResponseHeaders

    /// The response body data.
    public var body: Data

    /// Creates a response with the given components.
    public init(
        status: HTTPResponse.Status = .ok,
        headers: [String: String] = [:],
        body: Data = Data()
    ) {
        self.status = status
        self.headers = ResponseHeaders(headers)
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

/// HTTP response headers that support multiple values per header name.
///
/// Uses an ordered array of pairs internally so multiple `Set-Cookie` headers
/// (or any other multi-value header) are preserved correctly.
public struct ResponseHeaders: Sendable {
    private var storage: [(String, String)]

    public init() {
        self.storage = []
    }

    /// Creates headers from a single-value dictionary (convenience for migration).
    public init(_ dictionary: [String: String]) {
        self.storage = dictionary.map { ($0.key, $0.value) }
    }

    /// Gets the first value for a header name, or sets/replaces it.
    public subscript(name: String) -> String? {
        get {
            let lower = name.lowercased()
            return storage.first(where: { $0.0.lowercased() == lower })?.1
        }
        set {
            let lower = name.lowercased()
            storage.removeAll(where: { $0.0.lowercased() == lower })
            if let value = newValue {
                storage.append((name, value))
            }
        }
    }

    /// Adds a value for a header name without removing existing values.
    public mutating func add(name: String, value: String) {
        storage.append((name, value))
    }

    /// All values for a given header name.
    public func values(for name: String) -> [String] {
        let lower = name.lowercased()
        return storage.filter { $0.0.lowercased() == lower }.map(\.1)
    }
}

extension ResponseHeaders: Sequence {
    public func makeIterator() -> IndexingIterator<[(String, String)]> {
        storage.makeIterator()
    }
}
