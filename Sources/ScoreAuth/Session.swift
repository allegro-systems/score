import Foundation

/// A user session stored in the Score storage layer.
///
/// Each session binds a unique token to a user identifier and
/// carries creation and expiration timestamps. The storage layer
/// is responsible for enforcing the TTL; the ``isExpired`` property
/// provides a convenience check against the current wall clock.
public struct Session: Codable, Sendable, Expirable {

    /// The unique identifier for this session.
    public let id: String

    /// The identifier of the authenticated user.
    public let userID: String

    /// The bearer token associated with this session.
    public let token: Token

    /// The date and time when the session was created.
    public let createdAt: Date

    /// The date and time when the session expires.
    public let expiresAt: Date

    /// Creates a new session.
    ///
    /// - Parameters:
    ///   - id: Unique session identifier.
    ///   - userID: The authenticated user's identifier.
    ///   - token: The bearer token for this session.
    ///   - createdAt: Creation timestamp.
    ///   - expiresAt: Expiration timestamp.
    public init(
        id: String,
        userID: String,
        token: Token,
        createdAt: Date,
        expiresAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.token = token
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
