/// A hierarchical key for addressing values in a ``Store``.
///
/// Keys are composed of ordered string segments, forming a path
/// like `"users.42.profile"`. Keys are `Comparable`, `Hashable`,
/// and `Sendable`.
///
/// ```swift
/// let key = Key("users", "42", "profile")
/// key.description  // "users.42.profile"
/// key.hasPrefix(Key("users"))  // true
/// ```
public struct Key: Sendable, Hashable, Comparable, CustomStringConvertible {

    /// The ordered path segments of this key.
    public let segments: [String]

    /// Creates a key from variadic segments.
    public init(_ segments: String...) {
        self.segments = segments
    }

    /// Creates a key from an array of segments.
    public init(segments: [String]) {
        self.segments = segments
    }

    /// Dot-joined representation of the key's segments.
    public var description: String {
        segments.joined(separator: ".")
    }

    /// Returns `true` if this key starts with the given prefix key's segments.
    public func hasPrefix(_ other: Key) -> Bool {
        guard other.segments.count <= segments.count else { return false }
        return segments.prefix(other.segments.count).elementsEqual(other.segments)
    }

    /// Returns a new key with an additional segment appended.
    public func appending(_ segment: String) -> Key {
        Key(segments: segments + [segment])
    }

    public static func < (lhs: Key, rhs: Key) -> Bool {
        for (l, r) in zip(lhs.segments, rhs.segments) {
            if l < r { return true }
            if l > r { return false }
        }
        return lhs.segments.count < rhs.segments.count
    }
}
