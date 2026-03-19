import Foundation

/// A pluggable storage backend for `KVStore`.
///
/// Implement this protocol to provide custom storage engines
/// (e.g., FoundationDB, SQLite, Redis).
public protocol KVBackend: Sendable {

    /// Retrieves an entry by key.
    func get(key: KVKey) async throws -> KVEntry?

    /// Stores a value at the given key.
    func set(key: KVKey, value: Data) async throws

    /// Stores a value at the given key with an optional TTL (time-to-live).
    ///
    /// - Parameters:
    ///   - key: The storage key.
    ///   - value: The raw value data.
    ///   - ttl: Time-to-live duration. After this period, the entry is considered expired
    ///          and will be excluded from reads. Pass `nil` for no expiry.
    /// - Throws: A storage error if the write fails.
    func set(key: KVKey, value: Data, ttl: Duration?) async throws

    /// Deletes the entry at the given key.
    func delete(key: KVKey) async throws

    /// Checks whether a non-expired entry exists at the given key.
    func exists(key: KVKey) async throws -> Bool

    /// Lists entries matching the given prefix.
    func list(prefix: KVKey, limit: Int) async throws -> [KVEntry]

    /// Atomically increments an integer value at the given key.
    ///
    /// If the key does not exist, it is created with the increment value.
    /// Returns the new value after incrementing.
    func increment(key: KVKey, by delta: Int64) async throws -> Int64

    /// Executes an atomic batch of operations.
    func commitAtomic(_ operations: [AtomicOp]) async throws

    /// Removes all expired entries. Called periodically by the runtime.
    func sweepExpired() async throws
}

// MARK: - Default Implementations

extension KVBackend {

    /// Default: delegates to `set(key:value:)` with no TTL.
    public func set(key: KVKey, value: Data, ttl: Duration?) async throws {
        try await set(key: key, value: value)
    }

    /// Default: checks via `get`.
    public func exists(key: KVKey) async throws -> Bool {
        try await get(key: key) != nil
    }

    /// Default: no-op (backends without TTL have nothing to sweep).
    public func sweepExpired() async throws {}

    /// Default: read-modify-write (not truly atomic without backend support).
    public func increment(key: KVKey, by delta: Int64) async throws -> Int64 {
        let current: Int64
        if let entry = try await get(key: key) {
            current = (try? JSONDecoder().decode(Int64.self, from: entry.value)) ?? 0
        } else {
            current = 0
        }
        let newValue = current + delta
        let data = try JSONEncoder().encode(newValue)
        try await set(key: key, value: data)
        return newValue
    }
}

/// An individual operation within an atomic batch.
public enum AtomicOp: Sendable {
    case set(key: KVKey, value: Data)
    case setWithTTL(key: KVKey, value: Data, ttl: Duration)
    case delete(key: KVKey)
    case check(key: KVKey, versionStamp: UInt64?)
}
