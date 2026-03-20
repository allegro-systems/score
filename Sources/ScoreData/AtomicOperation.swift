import Foundation
import os

/// A builder for atomic multi-key operations.
///
/// Atomic operations allow multiple reads and writes to execute
/// as a single transaction, with optimistic concurrency checks.
///
/// ### Example
///
/// ```swift
/// try await store.atomic()
///     .check(key: ["counter"], versionStamp: entry.versionStamp)
///     .set(key: ["counter"], value: newValue)
///     .commit()
/// ```
public final class AtomicOperation: Sendable {

    private let backend: any KVBackend
    private let operations = OSAllocatedUnfairLock<[AtomicOp]>(initialState: [])

    init(backend: any KVBackend) {
        self.backend = backend
    }

    /// Adds a version check for optimistic concurrency.
    @discardableResult
    public func check(key: [String], versionStamp: UInt64?) -> AtomicOperation {
        operations.withLock { $0.append(.check(key: KVKey(parts: key), versionStamp: versionStamp)) }
        return self
    }

    /// Adds a set operation to the atomic batch.
    @discardableResult
    public func set<T: Codable & Sendable>(key: [String], value: T) throws -> AtomicOperation {
        let data = try JSONEncoder().encode(value)
        operations.withLock { $0.append(.set(key: KVKey(parts: key), value: data)) }
        return self
    }

    /// Adds a set operation with TTL to the atomic batch.
    @discardableResult
    public func set<T: Codable & Sendable>(key: [String], value: T, ttl: Duration) throws -> AtomicOperation {
        let data = try JSONEncoder().encode(value)
        operations.withLock { $0.append(.setWithTTL(key: KVKey(parts: key), value: data, ttl: ttl)) }
        return self
    }

    /// Adds a delete operation to the atomic batch.
    @discardableResult
    public func delete(key: [String]) -> AtomicOperation {
        operations.withLock { $0.append(.delete(key: KVKey(parts: key))) }
        return self
    }

    /// Commits all operations atomically.
    public func commit() async throws {
        let ops = operations.withLock { $0 }
        try await backend.commitAtomic(ops)
    }
}
