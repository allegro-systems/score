/// Configuration for the Score authentication system.
///
/// Provides sensible defaults for session lifetimes, magic link validity
/// windows, CSRF token duration, rate limiting, and cookie policy.
///
/// ```swift
/// let config = AuthConfig()
/// // config.sessionTTL == .seconds(86400)   — 24 hours
/// // config.magicLinkTTL == .seconds(600)    — 10 minutes
/// ```
public struct AuthConfig: Sendable {

    /// How long a session remains valid after creation.
    public var sessionTTL: Duration

    /// How long a magic link token remains valid after creation.
    public var magicLinkTTL: Duration

    /// How long a CSRF token remains valid after creation.
    public var csrfTTL: Duration

    /// Rate limiting policy for authentication attempts.
    public var rateLimit: RateLimit

    /// The name of the session cookie sent to the client.
    public var cookieName: String

    /// Whether the session cookie requires a secure (HTTPS) connection.
    public var isCookieSecure: Bool

    /// The `SameSite` policy applied to the session cookie.
    public var cookieSameSite: SameSitePolicy

    /// Creates a new authentication configuration with the given values.
    ///
    /// - Parameters:
    ///   - sessionTTL: Session lifetime. Defaults to 24 hours.
    ///   - magicLinkTTL: Magic link lifetime. Defaults to 10 minutes.
    ///   - csrfTTL: CSRF token lifetime. Defaults to 1 hour.
    ///   - rateLimit: Rate limiting policy. Defaults to 5 attempts per 15 minutes.
    ///   - cookieName: Cookie name. Defaults to `"score_session"`.
    ///   - isCookieSecure: Require HTTPS. Defaults to `true`.
    ///   - cookieSameSite: SameSite policy. Defaults to `.lax`.
    public init(
        sessionTTL: Duration = .seconds(86400),
        magicLinkTTL: Duration = .seconds(600),
        csrfTTL: Duration = .seconds(3600),
        rateLimit: RateLimit = RateLimit(),
        cookieName: String = "score_session",
        isCookieSecure: Bool = true,
        cookieSameSite: SameSitePolicy = .lax
    ) {
        self.sessionTTL = sessionTTL
        self.magicLinkTTL = magicLinkTTL
        self.csrfTTL = csrfTTL
        self.rateLimit = rateLimit
        self.cookieName = cookieName
        self.isCookieSecure = isCookieSecure
        self.cookieSameSite = cookieSameSite
    }

    /// Rate limiting policy for authentication endpoints.
    public struct RateLimit: Sendable {

        /// Maximum number of attempts allowed within the window.
        public var attempts: Int

        /// The time window over which attempts are counted.
        public var window: Duration

        /// Creates a new rate limit policy.
        ///
        /// - Parameters:
        ///   - attempts: Maximum attempts. Defaults to `5`.
        ///   - window: Time window. Defaults to 15 minutes.
        public init(attempts: Int = 5, window: Duration = .seconds(900)) {
            precondition(attempts > 0, "RateLimit attempts must be greater than zero")
            precondition(window > .zero, "RateLimit window must be greater than zero")
            self.attempts = attempts
            self.window = window
        }
    }

    /// The `SameSite` attribute for the session cookie.
    public enum SameSitePolicy: String, Sendable {

        /// The cookie is only sent with same-site requests.
        case strict = "Strict"

        /// The cookie is sent with same-site requests and top-level navigations.
        case lax = "Lax"

        /// The cookie is sent with all requests (requires `Secure`).
        case none = "None"
    }
}
