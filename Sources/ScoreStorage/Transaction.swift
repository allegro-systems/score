import Foundation

/// An atomic scope for reading and writing multiple keys.
///
/// Transactions provide snapshot isolation: reads within a transaction see a
/// consistent view of the store as of the transaction's start, and all writes
/// are applied atomically on commit.
///
/// Implementations must be `Sendable` so that transactions can be passed
/// across concurrency domains.
public protocol Transaction: Sendable {

    /// Reads the raw value for the given key within this transaction.
    ///
    /// - Parameter key: The key to read.
    /// - Returns: The stored data, or `nil` if the key does not exist.
    /// - Throws: An error if the underlying storage backend fails.
    func get(_ key: Key) async throws -> Data?

    /// Stages a write of `value` for the given key within this transaction.
    ///
    /// The write becomes visible to other readers only when the transaction
    /// commits successfully.
    ///
    /// - Parameters:
    ///   - key: The key to write.
    ///   - value: The raw data to store.
    ///   - ttl: An optional duration after which the entry expires.
    /// - Throws: An error if the underlying storage backend fails.
    func set(_ key: Key, value: Data, ttl: Duration?) async throws

    /// Stages a deletion of the given key within this transaction.
    ///
    /// - Parameter key: The key to delete.
    /// - Throws: An error if the underlying storage backend fails.
    func delete(_ key: Key) async throws
}

extension Transaction {

    /// Stages a write without a time-to-live.
    ///
    /// - Parameters:
    ///   - key: The key to write.
    ///   - value: The raw data to store.
    /// - Throws: An error if the underlying storage backend fails.
    public func set(_ key: Key, value: Data) async throws {
        try await set(key, value: value, ttl: nil)
    }
}
