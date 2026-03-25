import Foundation

#if canImport(Security)
import Security
#endif

/// Utilities for generating cryptographically secure random values.
public enum CryptoRandom {

    /// Generates cryptographically secure random bytes.
    ///
    /// Uses `SecRandomCopyBytes` on Apple platforms and `/dev/urandom`
    /// on Linux and FreeBSD.
    ///
    /// - Parameter count: The number of random bytes to generate.
    /// - Returns: An array of random bytes.
    public static func bytes(_ count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        #if canImport(Security)
        let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        if status != errSecSuccess {
            var fallback = SystemRandomNumberGenerator()
            for i in bytes.indices {
                bytes[i] = UInt8.random(in: .min ... .max, using: &fallback)
            }
        }
        #else
        // Linux / FreeBSD: read from /dev/urandom
        guard let file = fopen("/dev/urandom", "r") else { return bytes }
        fread(&bytes, 1, count, file)
        fclose(file)
        #endif
        return bytes
    }

    /// Generates a cryptographically secure hex-encoded token.
    ///
    /// - Parameter byteCount: The number of random bytes (token will be
    ///   twice this length in hex characters). Defaults to 32 (64 hex chars).
    /// - Returns: A lowercase hex string.
    public static func hexToken(byteCount: Int = 32) -> String {
        bytes(byteCount).map { String(format: "%02x", $0) }.joined()
    }

    /// Generates cryptographically secure random data.
    ///
    /// - Parameter count: The number of random bytes.
    /// - Returns: A `Data` value containing the random bytes.
    public static func data(_ count: Int) -> Data {
        Data(bytes(count))
    }
}
