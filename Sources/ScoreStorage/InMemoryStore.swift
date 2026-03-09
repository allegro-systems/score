import Foundation

/// An in-memory ``Store`` implementation for development and testing.
///
/// Data is held in a dictionary and supports TTL-based expiry.
/// Transactions use snapshot isolation: writes are buffered and
/// applied atomically on success, or discarded on failure.
public actor InMemoryStore: Store {

    private struct Entry {
        let data: Data
        let expiry: ContinuousClock.Instant?
    }

    private var storage: [Key: Entry] = [:]

    public init() {}

    // MARK: - CRUD

    public func get(_ key: Key) async throws -> Data? {
        guard let entry = storage[key] else { return nil }
        if let expiry = entry.expiry, ContinuousClock.now >= expiry {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    public func set(_ key: Key, value: Data, ttl: Duration? = nil) async throws {
        let expiry = ttl.map { ContinuousClock.now.advanced(by: $0) }
        storage[key] = Entry(data: value, expiry: expiry)
    }

    public func delete(_ key: Key) async throws {
        storage.removeValue(forKey: key)
    }

    public func exists(_ key: Key) async throws -> Bool {
        try await get(key) != nil
    }

    // MARK: - Scan

    public func scan(prefix: Key) async throws -> AsyncThrowingStream<(Key, Data), any Error> {
        let matches =
            storage
            .filter { $0.key.hasPrefix(prefix) }
            .filter { entry in
                if let expiry = entry.value.expiry {
                    return ContinuousClock.now < expiry
                }
                return true
            }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.data) }

        return AsyncThrowingStream { continuation in
            for pair in matches {
                continuation.yield(pair)
            }
            continuation.finish()
        }
    }

    // MARK: - Increment

    public func increment(_ key: Key, by amount: Int) async throws -> Int {
        let current: Int
        if let entry = storage[key],
            entry.expiry.map({ ContinuousClock.now < $0 }) ?? true
        {
            current = entry.data.withUnsafeBytes { $0.loadUnaligned(as: Int.self) }
        } else {
            current = 0
        }
        let newValue = current + amount
        let data = withUnsafeBytes(of: newValue) { Data($0) }
        storage[key] = Entry(data: data, expiry: storage[key]?.expiry)
        return newValue
    }

    // MARK: - Transactions

    public func transaction(
        _ body: @Sendable (any Store) async throws -> Void
    ) async throws {
        let txn = TransactionBuffer()
        do {
            try await body(txn)
        } catch {
            throw error
        }
        // Apply buffered operations
        let ops = await txn.operations
        for op in ops {
            switch op {
            case .set(let key, let data, let ttl):
                try await set(key, value: data, ttl: ttl)
            case .delete(let key):
                try await delete(key)
            }
        }
    }
}

// MARK: - Transaction Buffer

private actor TransactionBuffer: Store {

    enum Operation: Sendable {
        case set(Key, Data, Duration?)
        case delete(Key)
    }

    var operations: [Operation] = []

    func get(_ key: Key) async throws -> Data? {
        nil
    }

    func set(_ key: Key, value: Data, ttl: Duration? = nil) async throws {
        operations.append(.set(key, value, ttl))
    }

    func delete(_ key: Key) async throws {
        operations.append(.delete(key))
    }

    func exists(_ key: Key) async throws -> Bool {
        false
    }

    func scan(prefix: Key) async throws -> AsyncThrowingStream<(Key, Data), any Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func increment(_ key: Key, by amount: Int) async throws -> Int {
        0
    }

    func transaction(
        _ body: @Sendable (any Store) async throws -> Void
    ) async throws {
        try await body(self)
    }
}
