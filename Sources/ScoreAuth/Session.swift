import Foundation
import ScoreCore

/// A user session with an expiration time.
public struct Session: Sendable, Codable, Equatable {

    /// Unique session identifier.
    public let id: String

    /// The authenticated user's identifier.
    public let userId: String

    /// When the session was created.
    public let createdAt: Date

    /// When the session expires.
    public let expiresAt: Date

    /// Additional metadata stored with the session.
    public var metadata: [String: String]

    public init(
        id: String = CryptoRandom.hexToken(),
        userId: String,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(86400 * 7),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.metadata = metadata
    }

    /// Whether the session has expired.
    public var isExpired: Bool { Date() > expiresAt }
}
