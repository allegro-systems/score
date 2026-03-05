/// Errors raised by the Score authentication system.
public enum AuthError: Error, Sendable {

    /// The supplied credentials could not be verified.
    case invalidCredentials

    /// The session has passed its expiration time.
    case sessionExpired

    /// No session was found for the given identifier.
    case sessionNotFound(String)

    /// The magic link or bearer token has expired.
    case tokenExpired

    /// The CSRF token in the request does not match the expected value.
    case csrfMismatch

    /// Too many authentication attempts within the configured window.
    case rateLimited

    /// The authentication email could not be delivered.
    case emailSendFailed(String)
}
