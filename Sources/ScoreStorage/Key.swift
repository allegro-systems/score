import Foundation

/// A structured, hierarchical key for the Score storage layer.
///
/// Keys are composed of ordered string segments forming a path-like tuple,
/// suitable for use with ordered key-value stores such as FoundationDB.
///
/// ### Example
///
/// ```swift
/// let key = Key("users", userId, "profile")
/// let prefix = Key("users", userId)
/// key.hasPrefix(prefix) // true
/// ```
public struct Key: Sendable, Hashable, Comparable, CustomStringConvertible {

    /// The ordered string segments that form this key.
    public let segments: [String]

    /// Creates a key from one or more string segments.
    ///
    /// - Parameter segments: The ordered path components of the key.
    public init(_ segments: String...) {
        self.segments = segments
    }

    /// Creates a key from an array of string segments.
    ///
    /// - Parameter segments: The ordered path components of the key.
    public init(segments: [String]) {
        self.segments = segments
    }

    /// Returns `true` if this key starts with the given prefix key.
    ///
    /// A key has prefix `p` when its leading segments match all segments of `p`.
    ///
    /// - Parameter prefix: The key to test as a prefix.
    /// - Returns: `true` if the receiver begins with the segments of `prefix`.
    public func hasPrefix(_ prefix: Key) -> Bool {
        guard prefix.segments.count <= segments.count else { return false }
        return segments.prefix(prefix.segments.count).elementsEqual(prefix.segments)
    }

    /// Returns a new key with the given segment appended.
    ///
    /// - Parameter segment: The segment to append.
    /// - Returns: A new key with the additional trailing segment.
    public func appending(_ segment: String) -> Key {
        Key(segments: segments + [segment])
    }

    /// A dot-separated textual representation of the key's segments.
    public var description: String {
        segments.joined(separator: ".")
    }

    /// Lexicographic comparison of two keys by their segments.
    public static func < (lhs: Key, rhs: Key) -> Bool {
        for (l, r) in zip(lhs.segments, rhs.segments) {
            if l < r { return true }
            if l > r { return false }
        }
        return lhs.segments.count < rhs.segments.count
    }
}
