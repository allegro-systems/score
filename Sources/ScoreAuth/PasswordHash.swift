import CommonCrypto
import Foundation

/// Utilities for password hashing and verification using SHA256 with salt.
///
/// Passwords are stored as `"hash:salt"` where `hash` is the SHA256 hex digest
/// of `password + salt`.
public enum PasswordHash {

    /// Verifies a plaintext password against a stored `"hash:salt"` string.
    ///
    /// - Parameters:
    ///   - password: The plaintext password to check.
    ///   - hash: The stored hash in `"sha256hex:salt"` format.
    /// - Returns: `true` if the password matches.
    public static func verify(_ password: String, against hash: String) -> Bool {
        let parts = hash.split(separator: ":")
        guard parts.count == 2 else { return false }
        let storedHash = String(parts[0])
        let salt = String(parts[1])
        return sha256(password + salt) == storedHash
    }

    /// Creates a `"hash:salt"` string from a plaintext password.
    ///
    /// - Parameter password: The plaintext password to hash.
    /// - Returns: A `"sha256hex:salt"` string suitable for storage.
    public static func hash(_ password: String) -> String {
        let salt = UUID().uuidString
        let digest = sha256(password + salt)
        return "\(digest):\(salt)"
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash) }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
