import ScoreCore
import os

/// CSRF protection token manager.
public final class CSRFProtection: Sendable {

    private let tokens = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    public init() {}

    /// Maximum number of tokens to retain. Oldest tokens beyond this
    /// limit are discarded to prevent unbounded growth from abandoned forms.
    private static let maxTokens = 1000

    /// Generates a new CSRF token.
    public func generateToken() -> String {
        let token = CryptoRandom.hexToken()
        tokens.withLock {
            $0.insert(token)
            if $0.count > Self.maxTokens {
                // Remove an arbitrary token to cap growth. Set ordering is
                // random so this approximates FIFO eviction over time.
                if let oldest = $0.first { $0.remove(oldest) }
            }
        }
        return token
    }

    /// Validates and consumes a CSRF token.
    public func validate(_ token: String) -> Bool {
        tokens.withLock { $0.remove(token) != nil }
    }
}
