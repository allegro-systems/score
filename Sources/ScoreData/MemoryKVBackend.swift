import Foundation
import os

/// An in-memory KV backend for development and testing.
///
/// Data is stored in a thread-safe dictionary and lost when the
/// process exits. Use this for local development, unit tests,
/// and prototyping.
public final class MemoryKVBackend: KVBackend, Sendable {

    private struct Entry: Sendable {
        var value: Data
        var versionStamp: UInt64
        var expiresAt: Date?
    }

    private struct State: Sendable {
        var storage: [KVKey: Entry] = [:]
        var nextVersion: UInt64 = 1

        mutating func bumpVersion() -> UInt64 {
            let v = nextVersion
            nextVersion += 1
            return v
        }
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public init() {}

    public func get(key: KVKey) async throws -> KVEntry? {
        state.withLock { state in
            guard let entry = state.storage[key] else { return nil }
            if let expiresAt = entry.expiresAt, expiresAt <= Date() { return nil }
            return KVEntry(key: key, value: entry.value, versionStamp: entry.versionStamp)
        }
    }

    public func set(key: KVKey, value: Data) async throws {
        state.withLock { state in
            state.storage[key] = Entry(value: value, versionStamp: state.bumpVersion(), expiresAt: nil)
        }
    }

    public func set(key: KVKey, value: Data, ttl: Duration?) async throws {
        state.withLock { state in
            let expiresAt = ttl.map { Date().addingTimeInterval(Double($0.components.seconds)) }
            state.storage[key] = Entry(value: value, versionStamp: state.bumpVersion(), expiresAt: expiresAt)
        }
    }

    public func delete(key: KVKey) async throws {
        state.withLock { state in
            _ = state.storage.removeValue(forKey: key)
        }
    }

    public func exists(key: KVKey) async throws -> Bool {
        state.withLock { state in
            guard let entry = state.storage[key] else { return false }
            if let expiresAt = entry.expiresAt, expiresAt <= Date() { return false }
            return true
        }
    }

    public func list(prefix: KVKey, limit: Int) async throws -> [KVEntry] {
        let now = Date()
        return state.withLock { state in
            state.storage
                .filter { $0.key.hasPrefix(prefix) && ($0.value.expiresAt.map { $0 > now } ?? true) }
                .sorted { $0.key.parts.lexicographicallyPrecedes($1.key.parts) }
                .prefix(limit)
                .map { KVEntry(key: $0.key, value: $0.value.value, versionStamp: $0.value.versionStamp) }
        }
    }

    public func sweepExpired() async throws {
        let now = Date()
        state.withLock { state in
            state.storage = state.storage.filter { $0.value.expiresAt.map { $0 > now } ?? true }
        }
    }

    public func commitAtomic(_ operations: [AtomicOp]) async throws {
        try state.withLock { state in
            for op in operations {
                if case .check(let key, let expectedVersion) = op {
                    let current = state.storage[key]?.versionStamp
                    if current != expectedVersion {
                        throw KVError.commitConflict(key: key)
                    }
                }
            }
            for op in operations {
                switch op {
                case .set(let key, let value):
                    state.storage[key] = Entry(value: value, versionStamp: state.bumpVersion(), expiresAt: nil)
                case .setWithTTL(let key, let value, let ttl):
                    let expiresAt = Date().addingTimeInterval(Double(ttl.components.seconds))
                    state.storage[key] = Entry(value: value, versionStamp: state.bumpVersion(), expiresAt: expiresAt)
                case .delete(let key):
                    _ = state.storage.removeValue(forKey: key)
                case .check:
                    break
                }
            }
        }
    }
}
