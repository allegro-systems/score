import Foundation

/// A CSRF protection token.
///
/// Generated server-side and embedded in forms or response headers,
/// then validated against the value submitted with subsequent requests
/// to prevent cross-site request forgery.
public struct CSRFToken: Sendable, Codable {

    /// The token string value.
    public let value: String

    /// Creates a CSRF token with the given string value.
    ///
    /// - Parameter value: The raw token string.
    public init(value: String) {
        self.value = value
    }

    /// Makes a new cryptographically random CSRF token.
    ///
    /// - Returns: A new CSRF token backed by 32 random bytes.
    public static func make() -> CSRFToken {
        let token = Token.make(byteCount: 32)
        return CSRFToken(value: token.value)
    }

    /// Compares two CSRF tokens in constant time to prevent timing attacks.
    ///
    /// - Parameters:
    ///   - lhs: The first token.
    ///   - rhs: The second token.
    /// - Returns: `true` if the tokens are equal.
    public static func constantTimeEqual(_ lhs: CSRFToken, _ rhs: CSRFToken) -> Bool {
        let lhsBytes = Array(lhs.value.utf8)
        let rhsBytes = Array(rhs.value.utf8)
        guard lhsBytes.count == rhsBytes.count else { return false }
        var result: UInt8 = 0
        for i in 0..<lhsBytes.count {
            result |= lhsBytes[i] ^ rhsBytes[i]
        }
        return result == 0
    }
}

extension CSRFToken: Hashable {

    public static func == (lhs: CSRFToken, rhs: CSRFToken) -> Bool {
        constantTimeEqual(lhs, rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
