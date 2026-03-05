import Foundation

extension Store {

    /// Reads and decodes a `Codable` value from the store.
    ///
    /// The value is decoded from JSON using `JSONDecoder`.
    ///
    /// - Parameters:
    ///   - type: The type to decode into.
    ///   - key: The key to read.
    /// - Returns: The decoded value, or `nil` if the key does not exist.
    /// - Throws: ``StorageError/decodingFailed(_:)`` if the stored data
    ///   cannot be decoded into the requested type.
    public func get<T: Codable & Sendable>(_ type: T.Type, forKey key: Key) async throws -> T? {
        guard let data = try await get(key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed("\(T.self): \(error.localizedDescription)")
        }
    }

    /// Encodes and writes a `Codable` value to the store.
    ///
    /// The value is encoded to JSON using `JSONEncoder`.
    ///
    /// - Parameters:
    ///   - value: The value to encode and store.
    ///   - key: The key to write.
    ///   - ttl: An optional duration after which the entry expires.
    /// - Throws: ``StorageError/encodingFailed(_:)`` if the value cannot
    ///   be encoded to JSON.
    public func set<T: Codable & Sendable>(
        _ value: T,
        forKey key: Key,
        ttl: Duration? = nil
    ) async throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(value)
        } catch {
            throw StorageError.encodingFailed("\(T.self): \(error.localizedDescription)")
        }
        try await set(key, value: data, ttl: ttl)
    }

    /// Atomically retrieves, decodes, and deletes a `Codable` value from the store.
    ///
    /// Combines ``getAndDelete(_:)`` with JSON decoding. Useful for consuming
    /// single-use tokens where the read and delete must be atomic.
    ///
    /// - Parameters:
    ///   - type: The type to decode into.
    ///   - key: The key to consume.
    /// - Returns: The decoded value, or `nil` if the key does not exist.
    /// - Throws: ``StorageError/decodingFailed(_:)`` if decoding fails.
    public func getAndDelete<T: Codable & Sendable>(
        _ type: T.Type,
        forKey key: Key
    ) async throws -> T? {
        guard let data = try await getAndDelete(key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed("\(T.self): \(error.localizedDescription)")
        }
    }
}
