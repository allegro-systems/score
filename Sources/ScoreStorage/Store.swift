import Foundation

/// A key-value storage backend.
///
/// `Store` defines the async interface for persisting and retrieving
/// data by hierarchical ``Key``. Implementations may be in-memory,
/// file-backed, or backed by external databases.
public protocol Store: Sendable {

    /// Returns the raw data for a key, or `nil` if absent or expired.
    func get(_ key: Key) async throws -> Data?

    /// Sets raw data for a key, with an optional time-to-live.
    func set(_ key: Key, value: Data, ttl: Duration?) async throws

    /// Removes a key. No-op if the key does not exist.
    func delete(_ key: Key) async throws

    /// Returns `true` if the key exists and has not expired.
    func exists(_ key: Key) async throws -> Bool

    /// Returns an async sequence of key-data pairs whose keys share the given prefix,
    /// sorted by key.
    func scan(prefix: Key) async throws -> AsyncThrowingStream<(Key, Data), any Error>

    /// Atomically increments (or creates) an integer counter and returns the new value.
    func increment(_ key: Key, by amount: Int) async throws -> Int

    /// Executes a closure within a transaction. If the closure throws,
    /// all writes within the transaction are rolled back.
    func transaction(_ body: @Sendable (any Store) async throws -> Void) async throws
}

// MARK: - Default TTL

extension Store {
    /// Convenience overload with no TTL.
    public func set(_ key: Key, value: Data) async throws {
        try await set(key, value: value, ttl: nil)
    }
}

// MARK: - Codable Convenience

extension Store {

    /// Encodes a `Codable` value and stores it.
    public func set<T: Codable & Sendable>(
        _ value: T,
        forKey key: Key,
        ttl: Duration? = nil
    ) async throws {
        let data = try JSONEncoder().encode(value)
        try await set(key, value: data, ttl: ttl)
    }

    /// Retrieves and decodes a `Codable` value, or returns `nil` if absent.
    public func get<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: Key
    ) async throws -> T? {
        guard let data = try await get(key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Retrieves, decodes, and then deletes a key atomically.
    public func getAndDelete<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: Key
    ) async throws -> T? {
        guard let data = try await get(key) else { return nil }
        try await delete(key)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
