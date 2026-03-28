import Foundation
import ScoreCore
import os

/// CSRF protection token manager.
public final class CSRFProtection: Sendable {

    private let tokens = OSAllocatedUnfairLock<[(token: String, createdAt: Date)]>(initialState: [])

    public init() {}

    /// Maximum number of tokens to retain. Oldest tokens are evicted first (FIFO).
    private static let maxTokens = 1000

    /// Generates a new CSRF token.
    public func generateToken() -> String {
        let token = CryptoRandom.hexToken()
        tokens.withLock {
            $0.append((token: token, createdAt: Date()))
            while $0.count > Self.maxTokens {
                $0.removeFirst()
            }
        }
        return token
    }

    /// Validates and consumes a CSRF token.
    public func validate(_ token: String) -> Bool {
        tokens.withLock { list in
            if let index = list.firstIndex(where: { $0.token == token }) {
                list.remove(at: index)
                return true
            }
            return false
        }
    }
}
