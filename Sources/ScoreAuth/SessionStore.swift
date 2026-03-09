import Foundation
import ScoreStorage

/// Manages session lifecycle using the Score storage layer.
///
/// Sessions are persisted as JSON-encoded data in a ``ScoreStorage/Store``
/// with TTL-based expiration. Each session is keyed by its bearer token
/// so that lookups during request authentication are fast.
///
/// ```swift
/// let store = SessionStore(storage: InMemoryStore(), config: AuthConfig())
/// let session = try await store.create(userID: "user_123")
/// let found = try await store.validate(token: session.token)
/// ```
public struct SessionStore: Sendable {

    /// The underlying key-value store.
    private let storage: any Store

    /// The authentication configuration controlling session TTL.
    private let config: AuthConfig

    /// Creates a new session store.
    ///
    /// - Parameters:
    ///   - storage: The key-value store used to persist sessions.
    ///   - config: Authentication configuration providing TTL values.
    public init(storage: any Store, config: AuthConfig) {
        self.storage = storage
        self.config = config
    }

    /// Creates a new session for the given user.
    ///
    /// - Parameter userID: The identifier of the authenticated user.
    /// - Returns: The newly created session.
    /// - Throws: ``StorageError`` if the session cannot be persisted.
    public func create(userID: String) async throws -> Session {
        let token = Token.make()
        let now = Date()
        let components = config.sessionTTL.components
        let ttlInterval = Double(components.seconds) + Double(components.attoseconds) / 1e18
        let expiresAt = now.addingTimeInterval(ttlInterval)
        let session = Session(
            id: UUID().uuidString,
            userID: userID,
            token: token,
            createdAt: now,
            expiresAt: expiresAt
        )
        try await storage.set(session, forKey: storageKey(for: token), ttl: config.sessionTTL)
        return session
    }

    /// Retrieves a session by its bearer token.
    ///
    /// - Parameter token: The bearer token to look up.
    /// - Returns: The session, or `nil` if not found.
    /// - Throws: ``StorageError`` if the storage layer fails.
    public func session(for token: Token) async throws -> Session? {
        try await storage.get(Session.self, forKey: storageKey(for: token))
    }

    /// Validates and returns a session, throwing if expired or missing.
    ///
    /// - Parameter token: The bearer token to validate.
    /// - Returns: The valid session.
    /// - Throws: ``AuthError/sessionNotFound(_:)`` or ``AuthError/sessionExpired``.
    public func validate(token: Token) async throws -> Session {
        guard let session = try await session(for: token) else {
            throw AuthError.sessionNotFound("***")
        }
        guard !session.isExpired else {
            try await delete(token: token)
            throw AuthError.sessionExpired
        }
        return session
    }

    /// Deletes a session by its bearer token.
    ///
    /// - Parameter token: The bearer token of the session to delete.
    /// - Throws: ``StorageError`` if the storage layer fails.
    public func delete(token: Token) async throws {
        try await storage.delete(storageKey(for: token))
    }

    private func storageKey(for token: Token) -> Key {
        Key("session", token.value)
    }
}
