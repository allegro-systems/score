import Foundation
import Testing

@testable import ScoreStorage

// MARK: - Key

@Test func keyInitFromVariadic() {
    let key = Key("users", "42", "profile")
    #expect(key.segments == ["users", "42", "profile"])
}

@Test func keyInitFromArray() {
    let key = Key(segments: ["a", "b", "c"])
    #expect(key.segments == ["a", "b", "c"])
}

@Test func keyDescription() {
    let key = Key("users", "42")
    #expect(key.description == "users.42")
}

@Test func keyEquality() {
    #expect(Key("a", "b") == Key("a", "b"))
    #expect(Key("a", "b") != Key("a", "c"))
}

@Test func keyComparableSameLength() {
    #expect(Key("a", "b") < Key("a", "c"))
    #expect(Key("b") > Key("a"))
}

@Test func keyComparableDifferentLength() {
    #expect(Key("a") < Key("a", "b"))
    #expect(Key("a", "b") > Key("a"))
}

@Test func keyHasPrefix() {
    let key = Key("users", "42", "profile")
    #expect(key.hasPrefix(Key("users")))
    #expect(key.hasPrefix(Key("users", "42")))
    #expect(key.hasPrefix(Key("users", "42", "profile")))
    #expect(!key.hasPrefix(Key("users", "42", "profile", "extra")))
    #expect(!key.hasPrefix(Key("posts")))
}

@Test func keyAppending() {
    let base = Key("users", "42")
    let extended = base.appending("profile")
    #expect(extended == Key("users", "42", "profile"))
}

@Test func keyHashable() {
    var set: Set<Key> = []
    set.insert(Key("a"))
    set.insert(Key("a"))
    set.insert(Key("b"))
    #expect(set.count == 2)
}

// MARK: - InMemoryStore CRUD

@Test func getReturnsNilForMissingKey() async throws {
    let store = InMemoryStore()
    let result = try await store.get(Key("missing"))
    #expect(result == nil)
}

@Test func setAndGet() async throws {
    let store = InMemoryStore()
    let data = Data("hello".utf8)
    try await store.set(Key("greeting"), value: data)
    let result = try await store.get(Key("greeting"))
    #expect(result == data)
}

@Test func deleteRemovesKey() async throws {
    let store = InMemoryStore()
    try await store.set(Key("temp"), value: Data("x".utf8))
    try await store.delete(Key("temp"))
    let result = try await store.get(Key("temp"))
    #expect(result == nil)
}

@Test func deleteNonExistentKeyIsNoOp() async throws {
    let store = InMemoryStore()
    try await store.delete(Key("nonexistent"))
}

@Test func overwriteExistingKey() async throws {
    let store = InMemoryStore()
    try await store.set(Key("k"), value: Data("v1".utf8))
    try await store.set(Key("k"), value: Data("v2".utf8))
    let result = try await store.get(Key("k"))
    #expect(result == Data("v2".utf8))
}

// MARK: - Scan

@Test func scanReturnsMatchingKeysInOrder() async throws {
    let store = InMemoryStore()
    try await store.set(Key("users", "b"), value: Data("B".utf8))
    try await store.set(Key("users", "a"), value: Data("A".utf8))
    try await store.set(Key("posts", "1"), value: Data("P".utf8))

    let stream = try await store.scan(prefix: Key("users"))
    var results: [(Key, Data)] = []
    for try await pair in stream {
        results.append(pair)
    }

    #expect(results.count == 2)
    #expect(results[0].0 == Key("users", "a"))
    #expect(results[1].0 == Key("users", "b"))
}

@Test func scanReturnsEmptyForNoMatch() async throws {
    let store = InMemoryStore()
    try await store.set(Key("users", "1"), value: Data("U".utf8))
    let stream = try await store.scan(prefix: Key("posts"))
    var count = 0
    for try await _ in stream { count += 1 }
    #expect(count == 0)
}

// MARK: - TTL

@Test func ttlExpiry() async throws {
    let store = InMemoryStore()
    try await store.set(Key("ephemeral"), value: Data("temp".utf8), ttl: .milliseconds(50))
    let before = try await store.get(Key("ephemeral"))
    #expect(before != nil)
    try await Task.sleep(for: .milliseconds(100))
    let after = try await store.get(Key("ephemeral"))
    #expect(after == nil)
}

@Test func existsReturnsFalseAfterExpiry() async throws {
    let store = InMemoryStore()
    try await store.set(Key("session"), value: Data("s".utf8), ttl: .milliseconds(50))
    #expect(try await store.exists(Key("session")) == true)
    try await Task.sleep(for: .milliseconds(100))
    #expect(try await store.exists(Key("session")) == false)
}

// MARK: - Exists

@Test func existsReturnsTrueForPresentKey() async throws {
    let store = InMemoryStore()
    try await store.set(Key("present"), value: Data("v".utf8))
    #expect(try await store.exists(Key("present")) == true)
}

@Test func existsReturnsFalseForMissingKey() async throws {
    let store = InMemoryStore()
    #expect(try await store.exists(Key("absent")) == false)
}

// MARK: - Increment

@Test func incrementCreatesNewKey() async throws {
    let store = InMemoryStore()
    let result = try await store.increment(Key("counter"), by: 5)
    #expect(result == 5)
}

@Test func incrementAddsToExisting() async throws {
    let store = InMemoryStore()
    _ = try await store.increment(Key("counter"), by: 10)
    let result = try await store.increment(Key("counter"), by: 3)
    #expect(result == 13)
}

@Test func incrementByNegative() async throws {
    let store = InMemoryStore()
    _ = try await store.increment(Key("counter"), by: 10)
    let result = try await store.increment(Key("counter"), by: -4)
    #expect(result == 6)
}

// MARK: - Transactions

@Test func transactionCommitsWrites() async throws {
    let store = InMemoryStore()
    try await store.set(Key("a"), value: Data("1".utf8))

    try await store.transaction { txn in
        _ = try await txn.get(Key("a"))
        try await txn.set(Key("b"), value: Data("2".utf8))
    }

    #expect(try await store.get(Key("b")) == Data("2".utf8))
}

@Test func transactionRollsBackOnThrow() async throws {
    let store = InMemoryStore()

    do {
        try await store.transaction { txn in
            try await txn.set(Key("c"), value: Data("3".utf8))
            throw StorageError.transactionConflict
        }
    } catch {}

    #expect(try await store.get(Key("c")) == nil)
}

@Test func transactionDeleteCommits() async throws {
    let store = InMemoryStore()
    try await store.set(Key("d"), value: Data("4".utf8))

    try await store.transaction { txn in
        try await txn.delete(Key("d"))
    }

    #expect(try await store.get(Key("d")) == nil)
}

// MARK: - Codable extensions

struct Profile: Codable, Sendable, Equatable {
    let name: String
    let age: Int
}

@Test func codableRoundTrip() async throws {
    let store = InMemoryStore()
    let profile = Profile(name: "Alice", age: 30)

    try await store.set(profile, forKey: Key("users", "alice"))
    let retrieved = try await store.get(Profile.self, forKey: Key("users", "alice"))

    #expect(retrieved == profile)
}

@Test func codableGetReturnsNilForMissing() async throws {
    let store = InMemoryStore()
    let result = try await store.get(Profile.self, forKey: Key("users", "missing"))
    #expect(result == nil)
}

@Test func codableWithTTL() async throws {
    let store = InMemoryStore()
    let profile = Profile(name: "Bob", age: 25)

    try await store.set(profile, forKey: Key("session"), ttl: .milliseconds(50))
    let before = try await store.get(Profile.self, forKey: Key("session"))
    #expect(before == profile)
    try await Task.sleep(for: .milliseconds(100))
    let after = try await store.get(Profile.self, forKey: Key("session"))
    #expect(after == nil)
}

// MARK: - StorageError

@Test func storageErrorKeyNotFound() {
    let error = StorageError.keyNotFound(Key("test"))
    if case .keyNotFound(let key) = error {
        #expect(key == Key("test"))
    } else {
        #expect(Bool(false), "Expected keyNotFound case")
    }
}

@Test func storageErrorTransactionConflict() {
    let error = StorageError.transactionConflict
    if case .transactionConflict = error {
    } else {
        #expect(Bool(false), "Expected transactionConflict case")
    }
}
