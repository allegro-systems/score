import Foundation

/// A thread-safe, in-memory implementation of ``Store`` for development and testing.
///
/// Entries are held in a dictionary protected by an actor boundary. TTL
/// expiration is checked lazily on every read and periodically swept to
/// reclaim memory.
///
/// Transactions use snapshot isolation: the closure sees a frozen copy of
/// the store's state, and writes are applied atomically on commit only if
/// the keys read have not been modified by another writer in the interim.
public actor InMemoryStore: Store {

    struct Entry: Sendable {
        let data: Data
        let expiresAt: ContinuousClock.Instant?
    }

    private var entries: [Key: Entry] = [:]
    private var versions: [Key: UInt64] = [:]
    private var globalVersion: UInt64 = 0

    /// Creates an empty in-memory store.
    public init() {}

    public func get(_ key: Key) async throws -> Data? {
        guard let entry = entries[key] else { return nil }
        if let expiresAt = entry.expiresAt, ContinuousClock.now >= expiresAt {
            entries.removeValue(forKey: key)
            versions.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    public func set(_ key: Key, value: Data, ttl: Duration?) async throws {
        let expiresAt: ContinuousClock.Instant? = ttl.map { ContinuousClock.now.advanced(by: $0) }
        entries[key] = Entry(data: value, expiresAt: expiresAt)
        globalVersion += 1
        versions[key] = globalVersion
    }

    public func delete(_ key: Key) async throws {
        entries.removeValue(forKey: key)
        globalVersion += 1
        versions[key] = globalVersion
    }

    public func scan(prefix: Key) async throws -> AsyncThrowingStream<(Key, Data), Error> {
        sweepExpired()
        let snapshot =
            entries
            .filter { $0.key.hasPrefix(prefix) }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.data) }

        return AsyncThrowingStream { continuation in
            for pair in snapshot {
                continuation.yield(pair)
            }
            continuation.finish()
        }
    }

    public func transaction(
        _ body: @Sendable (any Transaction) async throws -> Void
    ) async throws {
        sweepExpired()
        let snapshotEntries = entries
        let snapshotVersions = versions
        let txn = InMemoryTransaction(snapshot: snapshotEntries)

        try await body(txn)

        let reads = await txn.readKeys
        for key in reads {
            if versions[key] != snapshotVersions[key] {
                throw StorageError.transactionConflict
            }
        }

        let writes = await txn.writes
        let deletes = await txn.deletes

        for (key, data) in writes {
            entries[key] = Entry(data: data, expiresAt: nil)
            globalVersion += 1
            versions[key] = globalVersion
        }

        for key in deletes {
            entries.removeValue(forKey: key)
            globalVersion += 1
            versions[key] = globalVersion
        }
    }

    public func increment(_ key: Key, by delta: Int) async throws -> Int {
        var current: Int = 0
        var existingExpiry: ContinuousClock.Instant?
        if let entry = entries[key] {
            if let expiresAt = entry.expiresAt, ContinuousClock.now >= expiresAt {
                entries.removeValue(forKey: key)
                versions.removeValue(forKey: key)
            } else {
                guard entry.data.count == MemoryLayout<Int>.size else {
                    throw StorageError.decodingFailed(
                        "Expected \(MemoryLayout<Int>.size)-byte integer at key \(key)"
                    )
                }
                current = entry.data.withUnsafeBytes { $0.loadUnaligned(as: Int.self) }
                existingExpiry = entry.expiresAt
            }
        }
        let newValue = current + delta
        var buffer = newValue
        let data = withUnsafeBytes(of: &buffer) { Data($0) }
        entries[key] = Entry(data: data, expiresAt: existingExpiry)
        globalVersion += 1
        versions[key] = globalVersion
        return newValue
    }

    public func getAndDelete(_ key: Key) async throws -> Data? {
        guard let entry = entries.removeValue(forKey: key) else { return nil }
        globalVersion += 1
        versions[key] = globalVersion
        if let expiresAt = entry.expiresAt, ContinuousClock.now >= expiresAt {
            versions.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    public func exists(_ key: Key) async throws -> Bool {
        guard let entry = entries[key] else { return false }
        if let expiresAt = entry.expiresAt, ContinuousClock.now >= expiresAt {
            entries.removeValue(forKey: key)
            versions.removeValue(forKey: key)
            return false
        }
        return true
    }

    private func sweepExpired() {
        let now = ContinuousClock.now
        for (key, entry) in entries {
            if let expiresAt = entry.expiresAt, now >= expiresAt {
                entries.removeValue(forKey: key)
                versions.removeValue(forKey: key)
            }
        }
    }
}

actor InMemoryTransaction: Transaction {

    private let snapshot: [Key: InMemoryStore.Entry]
    var readKeys: Set<Key> = []
    var writes: [(Key, Data)] = []
    var deletes: Set<Key> = []

    init(snapshot: [Key: InMemoryStore.Entry]) {
        self.snapshot = snapshot
    }

    func get(_ key: Key) async throws -> Data? {
        readKeys.insert(key)
        guard let entry = snapshot[key] else { return nil }
        if let expiresAt = entry.expiresAt, ContinuousClock.now >= expiresAt {
            return nil
        }
        return entry.data
    }

    func set(_ key: Key, value: Data) async throws {
        writes.append((key, value))
    }

    func delete(_ key: Key) async throws {
        deletes.insert(key)
    }
}
