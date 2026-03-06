import Foundation
import ScoreRuntime
import ScoreStorage

/// Middleware that enforces rate limiting on incoming requests.
///
/// `RateLimitMiddleware` tracks request counts per client identifier using
/// a ``Store`` backend and rejects requests that exceed the configured
/// ``AuthConfig/RateLimit`` threshold with a `429 Too Many Requests` response.
///
/// The client identifier defaults to the `X-Forwarded-For` header, falling
/// back to the request path when no forwarded header is present.
///
/// ### Example
///
/// ```swift
/// let store = InMemoryStore()
/// let config = AuthConfig.RateLimit(attempts: 10, window: .seconds(60))
/// let middleware = RateLimitMiddleware.middleware(config: config, store: store)
/// ```
public struct RateLimitMiddleware: Sendable {

    private init() {}

    /// Creates an ``HTTPMiddleware`` that enforces the given rate limit policy.
    ///
    /// - Parameters:
    ///   - config: The rate limit configuration specifying maximum attempts
    ///     and the sliding window duration.
    ///   - store: The storage backend used to track request counts.
    ///   - identifierExtractor: An optional closure to extract the client
    ///     identifier from a request. Defaults to using the `x-forwarded-for`
    ///     header or the request path.
    /// - Returns: An ``HTTPMiddleware`` that can be added to a server's
    ///   middleware pipeline.
    public static func middleware(
        config: AuthConfig.RateLimit,
        store: some Store,
        identifierExtractor: (@Sendable (RequestContext) -> String)? = nil
    ) -> HTTPMiddleware {
        let extractor: @Sendable (RequestContext) -> String = identifierExtractor ?? { request in
            request.headers["x-forwarded-for"] ?? request.headers["x-real-ip"] ?? "unknown"
        }

        return HTTPMiddleware { request, next in
            let identifier = extractor(request)
            let key = Key("rate_limit", identifier)

            let windowSeconds = ttlSeconds(from: config.window)
            let count = try await store.increment(key, by: 1)

            if count == 1 {
                let data = withUnsafeBytes(of: count) { Data($0) }
                try await store.set(key, value: data, ttl: config.window)
            }

            if count > config.attempts {
                let retryAfter = String(windowSeconds)
                return Response(
                    status: .tooManyRequests,
                    headers: [
                        "content-type": "text/plain; charset=utf-8",
                        "retry-after": retryAfter,
                    ],
                    body: Data("Too Many Requests".utf8)
                )
            }

            var response = try await next(request)
            response.headers["x-ratelimit-limit"] = String(config.attempts)
            response.headers["x-ratelimit-remaining"] = String(max(0, config.attempts - count))
            return response
        }
    }

    private static func ttlSeconds(from duration: Duration) -> Int {
        let (seconds, attoseconds) = duration.components
        if attoseconds > 0 {
            return Int(seconds) + 1
        }
        return Int(seconds)
    }
}
