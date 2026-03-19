import Foundation
import HTTPTypes
import Tracing

/// Creates a distributed tracing span per HTTP request.
struct RequestTracingMiddleware: Sendable {

    func withSpan<T: Sendable>(
        method: HTTPRequest.Method,
        path: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await Tracing.withSpan("\(method.rawValue) \(path)", ofKind: .server) { span in
            span.attributes["http.method"] = method.rawValue
            span.attributes["http.target"] = path
            let result = try await operation()
            if let response = result as? Response {
                span.attributes["http.status_code"] = Int(response.status.code)
            }
            return result
        }
    }
}
