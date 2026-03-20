/// Errors that can occur during authentication.
public enum AuthError: Error, Sendable {

    /// The magic link token is invalid or expired.
    case invalidToken

    /// The session was not found or has expired.
    case sessionExpired

    /// The CSRF token is invalid.
    case invalidCSRF

    /// The passkey credential was not found.
    case credentialNotFound

    /// The passkey sign count indicates a replay attack.
    case replayDetected

    /// The user was not found.
    case userNotFound
}
