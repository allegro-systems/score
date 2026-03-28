import Foundation
import HTTPTypes
import ScoreRuntime

/// Extracts a session cookie value from HTTP request headers.
public enum SessionCookie {

    /// Extracts the value of the named cookie from a `RequestContext`.
    ///
    /// - Parameters:
    ///   - ctx: The request context containing headers.
    ///   - name: The cookie name to extract (default: `"session"`).
    /// - Returns: The cookie value, or `nil` if not found.
    public static func extract(from ctx: RequestContext, name: String = "session") -> String? {
        guard let cookie = ctx.headers["cookie"] ?? ctx.headers["Cookie"] else {
            return nil
        }
        return cookie.split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { $0.hasPrefix("\(name)=") }
            .map { String($0.dropFirst(name.count + 1)) }
    }
}

/// A reusable auth guard that checks for a valid session and returns
/// an appropriate denial response when unauthenticated.
///
/// Configure it once with a session store, then call `requireAuth(_:)` in
/// your route handlers. API routes (paths starting with a configurable prefix)
/// get a 401 JSON response; page routes get a redirect to the login page.
///
/// ```swift
/// let guard = AuthGuard(sessionStore: mySessionStore)
///
/// // In a route handler:
/// if let denied = await guard.requireAuth(ctx) { return denied }
/// ```
public struct AuthGuard: Sendable {

    private let sessionStore: any SessionStore
    private let cookieName: String
    private let loginPath: String
    private let apiPathPrefix: String

    /// Creates an auth guard.
    ///
    /// - Parameters:
    ///   - sessionStore: The session store to validate sessions against.
    ///   - cookieName: The cookie name containing the session ID (default: `"session"`).
    ///   - loginPath: The path to redirect unauthenticated page requests to (default: `"/login"`).
    ///   - apiPathPrefix: The path prefix that identifies API routes (default: `"/api/"`).
    public init(
        sessionStore: any SessionStore,
        cookieName: String = "session",
        loginPath: String = "/login",
        apiPathPrefix: String = "/api/"
    ) {
        self.sessionStore = sessionStore
        self.cookieName = cookieName
        self.loginPath = loginPath
        self.apiPathPrefix = apiPathPrefix
    }

    /// Checks if the request has a valid session.
    ///
    /// - Returns: `nil` if the request is authenticated, or a denial `Response`
    ///   (401 JSON for API routes, 303 redirect for page routes).
    public func requireAuth(_ ctx: RequestContext) async -> Response? {
        guard let sessionId = SessionCookie.extract(from: ctx, name: cookieName) else {
            return denyResponse(for: ctx)
        }
        guard let session = try? await sessionStore.get(sessionID: sessionId) else {
            return denyResponse(for: ctx)
        }
        guard !session.isExpired else {
            try? await sessionStore.delete(sessionID: session.id)
            return denyResponse(for: ctx)
        }
        return nil
    }

    /// Returns the current session for the request, or `nil` if unauthenticated.
    public func currentSession(from ctx: RequestContext) async -> Session? {
        guard let sessionId = SessionCookie.extract(from: ctx, name: cookieName) else {
            return nil
        }
        return try? await sessionStore.get(sessionID: sessionId)
    }

    /// Creates an `HTTPMiddleware` that rejects unauthenticated requests.
    ///
    /// Requests to paths in `excludedPaths` (exact match) are passed through
    /// without checking authentication.
    ///
    /// ```swift
    /// let authMiddleware = guard.middleware(excluding: ["/login", "/auth/login"])
    /// ```
    public func middleware(excluding excludedPaths: Set<String> = []) -> HTTPMiddleware {
        let guard_ = self
        let excluded = excludedPaths
        return HTTPMiddleware { ctx, next in
            if excluded.contains(ctx.path) {
                return try await next(ctx)
            }
            if let denied = await guard_.requireAuth(ctx) {
                return denied
            }
            return try await next(ctx)
        }
    }

    // MARK: - Private

    private func denyResponse(for ctx: RequestContext) -> Response {
        let isAPI = ctx.path.hasPrefix(apiPathPrefix)
        let acceptsJSON = (ctx.headers["accept"] ?? ctx.headers["Accept"] ?? "").contains("application/json")

        if isAPI || acceptsJSON {
            return Response.json(
                Data(#"{"error":"Not authenticated"}"#.utf8),
                status: .unauthorized
            )
        }
        return Response(
            status: .seeOther,
            headers: ["location": loginPath]
        )
    }
}
