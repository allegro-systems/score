import Foundation
import ScoreStorage

/// Manages magic link token lifecycle using the Score storage layer.
///
/// Magic link tokens are single-use: once validated, they are
/// immediately deleted from the store to prevent replay attacks.
///
/// ```swift
/// let store = MagicLinkStore(storage: InMemoryStore(), config: AuthConfig())
/// let link = try await store.create(email: "user@example.com")
/// let validated = try await store.validate(tokenValue: link.token.value)
/// ```
public struct MagicLinkStore: Sendable {

    /// The underlying key-value store.
    private let storage: any Store

    /// The authentication configuration controlling magic link TTL.
    private let config: AuthConfig

    /// Creates a new magic link store.
    ///
    /// - Parameters:
    ///   - storage: The key-value store used to persist magic link tokens.
    ///   - config: Authentication configuration providing TTL values.
    public init(storage: any Store, config: AuthConfig) {
        self.storage = storage
        self.config = config
    }

    /// Creates a new magic link token for the given email address.
    ///
    /// - Parameter email: The recipient email address.
    /// - Returns: The newly created magic link.
    /// - Throws: ``StorageError`` if the token cannot be persisted.
    public func create(email: String) async throws -> MagicLink {
        let token = Token.make()
        let now = Date()
        let components = config.magicLinkTTL.components
        let ttlInterval = Double(components.seconds) + Double(components.attoseconds) / 1e18
        let expiresAt = now.addingTimeInterval(ttlInterval)
        let link = MagicLink(
            token: token,
            email: email,
            createdAt: now,
            expiresAt: expiresAt
        )
        try await storage.set(link, forKey: storageKey(for: token.value), ttl: config.magicLinkTTL)
        return link
    }

    /// Validates a magic link token and consumes it.
    ///
    /// The token is deleted from the store after successful validation
    /// to enforce single-use semantics.
    ///
    /// - Parameter tokenValue: The raw token string from the magic link URL.
    /// - Returns: The validated magic link.
    /// - Throws: ``AuthError/tokenExpired`` if the token has expired or does not exist.
    public func validate(tokenValue: String) async throws -> MagicLink {
        let key = storageKey(for: tokenValue)
        guard let link = try await storage.getAndDelete(MagicLink.self, forKey: key) else {
            throw AuthError.tokenExpired
        }
        guard !link.isExpired else {
            throw AuthError.tokenExpired
        }
        return link
    }

    private func storageKey(for tokenValue: String) -> Key {
        Key("magiclink", tokenValue)
    }
}
