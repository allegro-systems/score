import Foundation

/// A magic link token for passwordless email authentication.
///
/// When a user requests to sign in, a `MagicLink` is created and its
/// token is embedded in a URL sent via email. The token is single-use:
/// once validated it is deleted from the store.
public struct MagicLink: Codable, Sendable {

    /// The one-time-use token embedded in the magic link URL.
    public let token: Token

    /// The email address the magic link was sent to.
    public let email: String

    /// The date and time when the magic link was created.
    public let createdAt: Date

    /// The date and time when the magic link expires.
    public let expiresAt: Date

    /// Whether the magic link has passed its expiration time.
    public var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Creates a new magic link.
    ///
    /// - Parameters:
    ///   - token: The one-time-use token.
    ///   - email: The recipient email address.
    ///   - createdAt: Creation timestamp.
    ///   - expiresAt: Expiration timestamp.
    public init(
        token: Token,
        email: String,
        createdAt: Date,
        expiresAt: Date
    ) {
        self.token = token
        self.email = email
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
