import Foundation
import HTTPTypes

/// Configuration for Cross-Origin Resource Sharing (CORS).
public struct CORSConfiguration: Sendable {

    /// Allowed origin patterns. Use `["*"]` to allow all origins.
    public let allowedOrigins: [String]

    /// Allowed HTTP methods.
    public let allowedMethods: [String]

    /// Allowed request headers.
    public let allowedHeaders: [String]

    /// Headers exposed to the client.
    public let exposedHeaders: [String]

    /// Whether credentials (cookies, auth headers) are allowed.
    public let allowCredentials: Bool

    /// Max age in seconds for preflight cache.
    public let maxAge: Int?

    public init(
        allowedOrigins: [String] = ["*"],
        allowedMethods: [String] = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allowedHeaders: [String] = ["accept", "authorization", "content-type", "origin"],
        exposedHeaders: [String] = [],
        allowCredentials: Bool = false,
        maxAge: Int? = 86400
    ) {
        self.allowedOrigins = allowedOrigins
        self.allowedMethods = allowedMethods
        self.allowedHeaders = allowedHeaders
        self.exposedHeaders = exposedHeaders
        self.allowCredentials = allowCredentials
        self.maxAge = maxAge
    }

    /// A permissive configuration that allows all origins.
    public static let permissive = CORSConfiguration()

    /// A strict configuration that disallows all cross-origin requests.
    public static let strict = CORSConfiguration(allowedOrigins: [])
}

extension HTTPMiddleware {

    /// Creates a CORS middleware with the given configuration.
    public static func cors(_ config: CORSConfiguration = .permissive) -> HTTPMiddleware {
        HTTPMiddleware { request, next in
            let origin = request.headers["origin"] ?? request.headers["Origin"]

            let allowedOrigin: String?
            if config.allowedOrigins.contains("*") {
                allowedOrigin = config.allowCredentials ? origin : "*"
            } else if let origin, config.allowedOrigins.contains(where: { $0 == origin }) {
                allowedOrigin = origin
            } else {
                allowedOrigin = nil
            }

            if request.method == .options {
                var headers: [String: String] = [:]
                if let allowedOrigin {
                    headers["access-control-allow-origin"] = allowedOrigin
                    headers["access-control-allow-methods"] = config.allowedMethods.joined(separator: ", ")
                    headers["access-control-allow-headers"] = config.allowedHeaders.joined(separator: ", ")
                    if config.allowCredentials {
                        headers["access-control-allow-credentials"] = "true"
                    }
                    if let maxAge = config.maxAge {
                        headers["access-control-max-age"] = String(maxAge)
                    }
                    if !config.exposedHeaders.isEmpty {
                        headers["access-control-expose-headers"] = config.exposedHeaders.joined(separator: ", ")
                    }
                }
                return Response(status: .noContent, headers: headers)
            }

            var response = try await next(request)

            if let allowedOrigin {
                response.headers["access-control-allow-origin"] = allowedOrigin
                if config.allowCredentials {
                    response.headers["access-control-allow-credentials"] = "true"
                }
                if !config.exposedHeaders.isEmpty {
                    response.headers["access-control-expose-headers"] = config.exposedHeaders.joined(separator: ", ")
                }
            }

            return response
        }
    }
}
