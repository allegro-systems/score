import Foundation

/// A key-value entry stored in the KV store.
public struct KVEntry: Sendable, Equatable {

    /// The key for this entry.
    public let key: KVKey

    /// The raw encoded value.
    public let value: Data

    /// The version stamp for optimistic concurrency.
    public let versionStamp: UInt64

    public init(key: KVKey, value: Data, versionStamp: UInt64) {
        self.key = key
        self.value = value
        self.versionStamp = versionStamp
    }

    /// Decodes the value as the given type.
    public func decode<T: Codable>(_ type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: value)
    }
}
