import Foundation
import ScoreCore

/// A type-safe key-value store with support for typed values,
/// key prefixes, and atomic operations.
///
/// `KVStore` provides a Deno KV-inspired API for persistent storage.
/// Two built-in backends are provided:
///
/// - **`.persistent()`** — SQLite-backed, survives restarts (default for production)
/// - **`.memory()`** — In-process only, fast, lost on exit (sessions, caches, tests)
///
/// ### Example
///
/// ```swift
/// // Persistent store (SQLite) — default for data that must survive restarts
/// let db = try KVStore.persistent()
///
/// // In-memory store — for sessions, caches, and tests
/// let sessions = KVStore.memory()
///
/// // Common API — both backends share the same interface
/// try await db.set(key: ["users", "123"], value: User(name: "Alice"))
/// let user: User? = try await db.get(key: ["users", "123"])
/// let entries = try await db.list(prefix: ["users"])
/// ```
public struct KVStore: Sendable {

    private let backend: any KVBackend

    /// Creates a store backed by the given backend.
    public init(backend: any KVBackend) {
        self.backend = backend
    }

    // MARK: - Factory Methods

    /// Creates a persistent SQLite-backed store.
    ///
    /// Data is written to disk and survives process restarts. This is the
    /// recommended default for application data, user records, and any
    /// state that must not be lost.
    ///
    /// - Parameter path: The database file path. Defaults to `.score/data.db`
    ///   in the current working directory.
    /// - Returns: A `KVStore` backed by SQLite.
    /// - Throws: `KVError.serializationFailed` if the database cannot be opened.
    public static func persistent(path: String = ".score/data.db") throws -> KVStore {
        KVStore(backend: try SQLiteKVBackend(path: path))
    }

    /// Creates an in-memory store.
    ///
    /// Data lives only in process memory and is lost when the server stops.
    /// Use this for ephemeral state such as:
    /// - **User sessions** — fast lookups, auto-cleared on restart
    /// - **Rate limiting counters** — no need to persist
    /// - **Request caches** — rebuilt on startup anyway
    /// - **Tests** — isolated, zero cleanup
    public static func memory() -> KVStore {
        KVStore(backend: MemoryKVBackend())
    }

    // MARK: - Get

    /// Retrieves a typed value for the given key.
    public func get<T: Codable & Sendable>(key: [String]) async throws -> T? {
        guard let entry = try await backend.get(key: KVKey(parts: key)) else { return nil }
        return try JSONDecoder().decode(T.self, from: entry.value)
    }

    /// Retrieves a raw entry for the given key.
    public func getEntry(key: [String]) async throws -> KVEntry? {
        try await backend.get(key: KVKey(parts: key))
    }

    // MARK: - Set

    /// Stores a typed value at the given key.
    public func set<T: Codable & Sendable>(key: [String], value: T) async throws {
        let data = try JSONEncoder().encode(value)
        try await backend.set(key: KVKey(parts: key), value: data)
    }

    /// Stores a typed value at the given key with a TTL (time-to-live).
    ///
    /// After the TTL expires, the entry is no longer returned by reads.
    /// Useful for sessions, rate limiting, and caching.
    public func set<T: Codable & Sendable>(key: [String], value: T, ttl: Duration) async throws {
        let data = try JSONEncoder().encode(value)
        try await backend.set(key: KVKey(parts: key), value: data, ttl: ttl)
    }

    // MARK: - Delete

    /// Removes the value at the given key.
    public func delete(key: [String]) async throws {
        try await backend.delete(key: KVKey(parts: key))
    }

    // MARK: - List

    /// Lists entries matching the given prefix.
    public func list(prefix: [String], limit: Int = 100) async throws -> [KVEntry] {
        try await backend.list(prefix: KVKey(parts: prefix), limit: limit)
    }

    // MARK: - Exists

    /// Checks whether a non-expired entry exists at the given key.
    public func exists(key: [String]) async throws -> Bool {
        try await backend.exists(key: KVKey(parts: key))
    }

    // MARK: - Increment

    /// Atomically increments an integer value at the given key.
    /// Returns the new value after incrementing.
    public func increment(key: [String], by delta: Int64 = 1) async throws -> Int64 {
        try await backend.increment(key: KVKey(parts: key), by: delta)
    }

    // MARK: - Sweep

    /// Removes all expired entries. Call periodically to reclaim storage.
    public func sweepExpired() async throws {
        try await backend.sweepExpired()
    }

    // MARK: - Atomic

    /// Creates an atomic operation builder.
    public func atomic() -> AtomicOperation {
        AtomicOperation(backend: backend)
    }
}
