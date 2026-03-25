import Foundation
import Testing

@testable import ScoreData

private struct TestUser: Codable, Sendable, Equatable {
    let name: String
    let age: Int
}

// MARK: - Memory Backend Tests

@Suite("KVStore.memory")
struct MemoryKVStoreTests {

    @Test("Set and get a value")
    func setAndGet() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["users", "1"], value: TestUser(name: "Alice", age: 30))
        let user: TestUser? = try await store.get(key: ["users", "1"])
        #expect(user == TestUser(name: "Alice", age: 30))
    }

    @Test("Get returns nil for missing key")
    func getMissing() async throws {
        let store = KVStore.memory()
        let result: String? = try await store.get(key: ["missing"])
        #expect(result == nil)
    }

    @Test("Delete removes a value")
    func deleteRemoves() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["key"], value: "value")
        try await store.delete(key: ["key"])
        let result: String? = try await store.get(key: ["key"])
        #expect(result == nil)
    }

    @Test("List returns entries by prefix")
    func listByPrefix() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["users", "1"], value: "Alice")
        try await store.set(key: ["users", "2"], value: "Bob")
        try await store.set(key: ["posts", "1"], value: "Hello")
        let entries = try await store.list(prefix: ["users"])
        #expect(entries.count == 2)
    }

    @Test("List respects limit")
    func listWithLimit() async throws {
        let store = KVStore.memory()
        for i in 1...10 {
            try await store.set(key: ["items", String(i)], value: i)
        }
        let entries = try await store.list(prefix: ["items"], limit: 3)
        #expect(entries.count == 3)
    }

    @Test("Atomic commit succeeds")
    func atomicCommit() async throws {
        let store = KVStore.memory()
        try await store.atomic()
            .set(key: ["a"], value: 1)
            .set(key: ["b"], value: 2)
            .commit()
        let a: Int? = try await store.get(key: ["a"])
        let b: Int? = try await store.get(key: ["b"])
        #expect(a == 1)
        #expect(b == 2)
    }

    @Test("Atomic check fails on version mismatch")
    func atomicCheckFails() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["counter"], value: 0)
        let entry = try await store.getEntry(key: ["counter"])
        let version = entry?.versionStamp

        try await store.set(key: ["counter"], value: 1)

        await #expect(throws: KVError.self) {
            try await store.atomic()
                .check(key: ["counter"], versionStamp: version)
                .set(key: ["counter"], value: 2)
                .commit()
        }
    }

    @Test("Atomic delete within transaction")
    func atomicDelete() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["temp"], value: "data")
        try await store.atomic().delete(key: ["temp"]).commit()
        let result: String? = try await store.get(key: ["temp"])
        #expect(result == nil)
    }

    @Test("Entry decode works")
    func entryDecode() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["user"], value: TestUser(name: "Bob", age: 25))
        let entry = try await store.getEntry(key: ["user"])
        let user = try entry?.decode(TestUser.self)
        #expect(user?.name == "Bob")
    }

    @Test("KVKey hasPrefix works correctly")
    func keyPrefix() {
        let key = KVKey(parts: ["users", "123", "email"])
        #expect(key.hasPrefix(KVKey(parts: ["users"])))
        #expect(key.hasPrefix(KVKey(parts: ["users", "123"])))
        #expect(!key.hasPrefix(KVKey(parts: ["posts"])))
    }

    @Test("Overwrite existing value")
    func overwrite() async throws {
        let store = KVStore.memory()
        try await store.set(key: ["key"], value: "first")
        try await store.set(key: ["key"], value: "second")
        let result: String? = try await store.get(key: ["key"])
        #expect(result == "second")
    }
}

// MARK: - SQLite Backend Tests

@Suite("KVStore.persistent (SQLite)")
struct SQLiteKVStoreTests {

    /// Creates a temporary SQLite store that is cleaned up after each test.
    private func makeTempStore() throws -> KVStore {
        let path = NSTemporaryDirectory() + "score-test-\(UUID().uuidString).db"
        return try KVStore.persistent(path: path)
    }

    @Test("Set and get a value")
    func setAndGet() async throws {
        let store = try makeTempStore()
        try await store.set(key: ["users", "1"], value: TestUser(name: "Alice", age: 30))
        let user: TestUser? = try await store.get(key: ["users", "1"])
        #expect(user == TestUser(name: "Alice", age: 30))
    }

    @Test("Get returns nil for missing key")
    func getMissing() async throws {
        let store = try makeTempStore()
        let result: String? = try await store.get(key: ["missing"])
        #expect(result == nil)
    }

    @Test("Delete removes a value")
    func deleteRemoves() async throws {
        let store = try makeTempStore()
        try await store.set(key: ["key"], value: "value")
        try await store.delete(key: ["key"])
        let result: String? = try await store.get(key: ["key"])
        #expect(result == nil)
    }

    @Test("List returns entries by prefix")
    func listByPrefix() async throws {
        let store = try makeTempStore()
        try await store.set(key: ["users", "1"], value: "Alice")
        try await store.set(key: ["users", "2"], value: "Bob")
        try await store.set(key: ["posts", "1"], value: "Hello")
        let entries = try await store.list(prefix: ["users"])
        #expect(entries.count == 2)
    }

    @Test("List respects limit")
    func listWithLimit() async throws {
        let store = try makeTempStore()
        for i in 1...10 {
            try await store.set(key: ["items", "\(String(format: "%02d", i))"], value: i)
        }
        let entries = try await store.list(prefix: ["items"], limit: 3)
        #expect(entries.count == 3)
    }

    @Test("Atomic commit succeeds")
    func atomicCommit() async throws {
        let store = try makeTempStore()
        try await store.atomic()
            .set(key: ["a"], value: 1)
            .set(key: ["b"], value: 2)
            .commit()
        let a: Int? = try await store.get(key: ["a"])
        let b: Int? = try await store.get(key: ["b"])
        #expect(a == 1)
        #expect(b == 2)
    }

    @Test("Atomic check fails on version mismatch")
    func atomicCheckFails() async throws {
        let store = try makeTempStore()
        try await store.set(key: ["counter"], value: 0)
        let entry = try await store.getEntry(key: ["counter"])
        let version = entry?.versionStamp

        try await store.set(key: ["counter"], value: 1)

        await #expect(throws: KVError.self) {
            try await store.atomic()
                .check(key: ["counter"], versionStamp: version)
                .set(key: ["counter"], value: 2)
                .commit()
        }
    }

    @Test("Overwrite existing value")
    func overwrite() async throws {
        let store = try makeTempStore()
        try await store.set(key: ["key"], value: "first")
        try await store.set(key: ["key"], value: "second")
        let result: String? = try await store.get(key: ["key"])
        #expect(result == "second")
    }

    @Test("Data persists across backend instances")
    func persistence() async throws {
        let path = NSTemporaryDirectory() + "score-persist-\(UUID().uuidString).db"
        let store1 = try KVStore.persistent(path: path)
        try await store1.set(key: ["persistent", "key"], value: "survives")

        // Create a new store pointing at the same file
        let store2 = try KVStore.persistent(path: path)
        let result: String? = try await store2.get(key: ["persistent", "key"])
        #expect(result == "survives")
    }

    @Test("VersionStamp resumes after reopen")
    func versionStampResumes() async throws {
        let path = NSTemporaryDirectory() + "score-version-\(UUID().uuidString).db"
        let store1 = try KVStore.persistent(path: path)
        try await store1.set(key: ["a"], value: 1)
        let entry1 = try await store1.getEntry(key: ["a"])
        let v1 = entry1?.versionStamp ?? 0

        let store2 = try KVStore.persistent(path: path)
        try await store2.set(key: ["b"], value: 2)
        let entry2 = try await store2.getEntry(key: ["b"])
        let v2 = entry2?.versionStamp ?? 0

        #expect(v2 > v1)
    }
}
