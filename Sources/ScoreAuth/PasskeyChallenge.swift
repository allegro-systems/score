import Foundation

/// A WebAuthn challenge for passkey authentication.
///
/// Challenges are generated server-side and sent to the client during
/// both registration and authentication ceremonies. They are bound to
/// a specific relying party and user, and expire after a short window.
public struct PasskeyChallenge: Codable, Sendable, Expirable {

    /// The Base64-encoded challenge value.
    public let challenge: String

    /// The relying party identifier (typically the site domain).
    public let relyingPartyID: String

    /// The identifier of the user performing the ceremony.
    public let userID: String

    /// The date and time when the challenge was created.
    public let createdAt: Date

    /// The date and time when the challenge expires.
    public let expiresAt: Date

    /// Creates a new passkey challenge.
    ///
    /// - Parameters:
    ///   - challenge: The Base64-encoded challenge bytes.
    ///   - relyingPartyID: The relying party identifier.
    ///   - userID: The user identifier.
    ///   - createdAt: Creation timestamp.
    ///   - expiresAt: Expiration timestamp.
    public init(
        challenge: String,
        relyingPartyID: String,
        userID: String,
        createdAt: Date,
        expiresAt: Date
    ) {
        self.challenge = challenge
        self.relyingPartyID = relyingPartyID
        self.userID = userID
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
