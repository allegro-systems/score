import Foundation
import HTTPTypes
import Metrics

/// Emits per-request metrics: counter and duration histogram.
struct RequestMetricsMiddleware: Sendable {
    func record(
        method: HTTPRequest.Method,
        path: String,
        response: Response,
        duration: TimeInterval
    ) {
        let dimensions: [(String, String)] = [
            ("method", method.rawValue),
            ("status", "\(response.status.code)"),
        ]
        Counter(label: "http_requests_total", dimensions: dimensions).increment()
        Timer(label: "http_request_duration_seconds", dimensions: [("method", method.rawValue)])
            .recordSeconds(duration)
    }
}
