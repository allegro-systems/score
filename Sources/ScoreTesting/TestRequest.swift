import Foundation
import HTTPTypes
import ScoreRuntime

/// A builder for creating test HTTP requests.
///
/// ### Example
///
/// ```swift
/// let request = TestRequest.get("/api/users")
/// let request = TestRequest.post("/api/users", body: jsonData, headers: ["content-type": "application/json"])
/// ```
public struct TestRequest: Sendable {

    /// Creates a GET request context.
    public static func get(
        _ path: String,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:]
    ) -> RequestContext {
        RequestContext(
            method: .get,
            path: path,
            headers: headers,
            queryParameters: queryParameters
        )
    }

    /// Creates a POST request context.
    public static func post(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) -> RequestContext {
        RequestContext(
            method: .post,
            path: path,
            headers: headers,
            body: body
        )
    }

    /// Creates a PUT request context.
    public static func put(
        _ path: String,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) -> RequestContext {
        RequestContext(
            method: .put,
            path: path,
            headers: headers,
            body: body
        )
    }

    /// Creates a DELETE request context.
    public static func delete(
        _ path: String,
        headers: [String: String] = [:]
    ) -> RequestContext {
        RequestContext(
            method: .delete,
            path: path,
            headers: headers
        )
    }
}
