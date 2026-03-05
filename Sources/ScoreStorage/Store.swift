import Foundation

/// A transactional key-value store.
///
/// `Store` is the central abstraction of `ScoreStorage`. It provides a
/// unified API for reading, writing, scanning, and transacting over
/// structured keys regardless of the backing implementation.
///
/// Implementations range from an in-memory store for local development
/// to production backends such as FoundationDB.
///
/// All methods are asynchronous and throwing to accommodate both local and
/// networked backends.
///
/// ### Example
///
/// ```swift
/// let store = InMemoryStore()
/// try await store.set(Key("users", userId), value: payload, ttl: .seconds(3600))
/// let data = try await store.get(Key("users", userId))
/// ```
public protocol Store: Sendable {

    /// Reads the raw value for the given key.
    ///
    /// - Parameter key: The key to read.
    /// - Returns: The stored data, or `nil` if the key does not exist or has expired.
    /// - Throws: An error if the underlying storage backend fails.
    func get(_ key: Key) async throws -> Data?

    /// Writes a raw value for the given key, optionally with a time-to-live.
    ///
    /// When `ttl` is non-nil the entry is treated as ephemeral and will be
    /// automatically removed after the specified duration. This is useful for
    /// sessions, rate-limit counters, and other transient data.
    ///
    /// - Parameters:
    ///   - key: The key to write.
    ///   - value: The raw data to store.
    ///   - ttl: An optional duration after which the entry expires.
    /// - Throws: An error if the underlying storage backend fails.
    func set(_ key: Key, value: Data, ttl: Duration?) async throws

    /// Deletes the value for the given key.
    ///
    /// Deleting a non-existent key is a no-op.
    ///
    /// - Parameter key: The key to delete.
    /// - Throws: An error if the underlying storage backend fails.
    func delete(_ key: Key) async throws

    /// Scans all key-value pairs whose keys begin with the given prefix.
    ///
    /// Results are yielded in key order. The returned stream may be empty if
    /// no keys match.
    ///
    /// - Parameter prefix: The key prefix to match.
    /// - Returns: An asynchronous stream of matching key-value pairs.
    /// - Throws: An error if the underlying storage backend fails.
    func scan(prefix: Key) async throws -> AsyncThrowingStream<(Key, Data), Error>

    /// Executes a transactional closure with snapshot isolation.
    ///
    /// All reads inside the closure see a consistent snapshot, and all writes
    /// are applied atomically when the closure returns without throwing.
    /// If the closure throws, all writes are discarded.
    ///
    /// - Parameter body: A closure that receives a ``Transaction`` and
    ///   performs reads and writes within that atomic scope.
    /// - Throws: ``StorageError/transactionConflict`` on conflict, or the
    ///   error thrown by `body`.
    func transaction(_ body: @Sendable (any Transaction) async throws -> Void) async throws

    /// Atomically increments an integer value stored at the given key.
    ///
    /// If the key does not exist it is created with an initial value of zero
    /// before the increment is applied. The stored representation is an
    /// 8-byte little-endian signed integer.
    ///
    /// - Parameters:
    ///   - key: The key whose value to increment.
    ///   - delta: The amount to add (may be negative).
    /// - Returns: The value after the increment.
    /// - Throws: An error if the underlying storage backend fails.
    func increment(_ key: Key, by delta: Int) async throws -> Int

    /// Returns `true` if the given key exists in the store.
    ///
    /// Expired ephemeral entries are not considered to exist.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: `true` if the key holds a value, `false` otherwise.
    /// - Throws: An error if the underlying storage backend fails.
    func exists(_ key: Key) async throws -> Bool

    /// Atomically retrieves and deletes the value for the given key.
    ///
    /// If the key exists, its value is returned and the key is removed from
    /// the store in a single atomic operation. This prevents TOCTOU races
    /// when consuming single-use tokens.
    ///
    /// - Parameter key: The key to consume.
    /// - Returns: The stored data, or `nil` if the key does not exist.
    /// - Throws: An error if the underlying storage backend fails.
    func getAndDelete(_ key: Key) async throws -> Data?
}

extension Store {

    /// Writes a raw value for the given key without a time-to-live.
    ///
    /// This convenience overload forwards to ``set(_:value:ttl:)`` with a
    /// `nil` TTL.
    ///
    /// - Parameters:
    ///   - key: The key to write.
    ///   - value: The raw data to store.
    /// - Throws: An error if the underlying storage backend fails.
    public func set(_ key: Key, value: Data) async throws {
        try await set(key, value: value, ttl: nil)
    }
}
