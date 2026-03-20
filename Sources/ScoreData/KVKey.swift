/// A structured key for addressing values in the KV store.
///
/// Keys are composed of string parts, forming a hierarchical path.
/// For example, `["users", "123", "email"]` represents a nested key.
public struct KVKey: Sendable, Hashable, CustomStringConvertible {

    /// The components of the key path.
    public let parts: [String]

    /// Creates a key from path components.
    public init(parts: [String]) {
        self.parts = parts
    }

    /// The string representation of the key, joined by `/`.
    public var description: String {
        parts.joined(separator: "/")
    }

    /// Whether this key starts with the given prefix.
    public func hasPrefix(_ prefix: KVKey) -> Bool {
        guard parts.count >= prefix.parts.count else { return false }
        return Array(parts.prefix(prefix.parts.count)) == prefix.parts
    }
}
