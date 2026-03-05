import CryptoKit
import Foundation

/// Computes content-based fingerprints for cache busting.
///
/// `AssetFingerprint` uses SHA256 hashing to produce deterministic,
/// content-derived identifiers for asset files. When the content of a file
/// changes, its fingerprint changes, allowing CDNs and browsers to serve
/// immutable cache headers while still invalidating stale assets.
public struct AssetFingerprint: Sendable {

    /// Computes a truncated SHA256 hex digest of the given data.
    ///
    /// The returned string is the first 8 hexadecimal characters of the
    /// full SHA256 digest, providing 32 bits of collision resistance — more
    /// than sufficient for cache-busting purposes.
    ///
    /// - Parameter data: The raw bytes to hash.
    /// - Returns: An 8-character lowercase hexadecimal string.
    public static func hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.prefix(4).map { String(format: "%02x", $0) }.joined()
    }

    /// Computes a fingerprint for a file at the given path.
    ///
    /// Reads the entire file into memory and returns its truncated SHA256
    /// hex digest.
    ///
    /// - Parameter path: The filesystem path to the file.
    /// - Returns: An 8-character lowercase hexadecimal string.
    /// - Throws: An error if the file cannot be read.
    public static func hash(contentsOf path: String) throws -> String {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return hash(data)
    }

    /// Returns a fingerprinted filename by inserting the content hash before
    /// the file extension.
    ///
    /// For example, given `"main.css"` and data that hashes to `"a1b2c3d4"`,
    /// the result is `"main-a1b2c3d4.css"`. Files without an extension have
    /// the hash appended with a hyphen separator.
    ///
    /// - Parameters:
    ///   - original: The original filename (e.g. `"style.css"`).
    ///   - data: The file's content used to compute the hash.
    /// - Returns: The fingerprinted filename.
    public static func fingerprintedName(original: String, data: Data) -> String {
        let fingerprint = hash(data)
        let url = URL(fileURLWithPath: original)
        let ext = url.pathExtension
        if ext.isEmpty {
            return "\(original)-\(fingerprint)"
        }
        let stem = url.deletingPathExtension().lastPathComponent
        return "\(stem)-\(fingerprint).\(ext)"
    }
}
