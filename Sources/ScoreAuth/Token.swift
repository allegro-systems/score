import Crypto
import Foundation

/// A cryptographically random bearer token.
///
/// Tokens are generated using a secure random byte source and
/// encoded as URL-safe Base64 strings. They are used as opaque
/// identifiers for sessions and magic links.
///
/// ```swift
/// let token = Token.generate()
/// print(token.value) // e.g. "dGhpcyBpcyBhIHRva2Vu..."
/// ```
public struct Token: Sendable, Hashable, Codable {

    /// The URL-safe Base64-encoded string representation of the token.
    public let value: String

    /// Creates a token with the given string value.
    ///
    /// - Parameter value: The raw token string.
    public init(value: String) {
        self.value = value
    }

    /// Generates a new cryptographically random token.
    ///
    /// - Parameter byteCount: The number of random bytes to use. Defaults to `32`.
    /// - Returns: A new token whose value is URL-safe Base64-encoded.
    public static func generate(byteCount: Int = 32) -> Token {
        precondition(byteCount > 0, "byteCount must be positive")
        let key = SymmetricKey(size: .init(bitCount: byteCount * 8))
        let encoded = key.withUnsafeBytes { Data($0) }.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return Token(value: encoded)
    }
}
