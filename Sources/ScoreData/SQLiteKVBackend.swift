import Foundation
import SQLite3
import ScoreCore

/// SQLite transient destructor constant, avoiding repeated `unsafeBitCast` calls.
private let sqliteTransientPtr = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A persistent KV backend backed by SQLite.
///
/// Data is stored in a single SQLite database file and survives process
/// restarts. This is the recommended backend for production server apps.
///
/// ### Example
///
/// ```swift
/// let store = try KVStore.persistent()
/// let store = try KVStore.persistent(path: "/var/data/app.db")
/// ```
public final class SQLiteKVBackend: KVBackend, @unchecked Sendable {

    private var db: OpaquePointer?
    private var nextVersion: UInt64

    // Cached prepared statements
    private var getStmt: OpaquePointer?
    private var setStmt: OpaquePointer?
    private var deleteStmt: OpaquePointer?
    private let lock = NSLock()

    /// Opens or creates a SQLite database at the given path.
    ///
    /// - Parameter path: The file path for the database. Parent directories
    ///   are created automatically. Use `":memory:"` for an in-process
    ///   database that is not written to disk.
    /// - Throws: `KVError.serializationFailed` if the database cannot be opened.
    public init(path: String) throws {
        if path != ":memory:" {
            let dir = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &dbPointer, flags, nil) == SQLITE_OK else {
            let message = dbPointer.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            sqlite3_close(dbPointer)
            throw KVError.serializationFailed("Failed to open database: \(message)")
        }
        self.db = dbPointer

        sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)

        let createSQL = """
            CREATE TABLE IF NOT EXISTS kv (
                key TEXT PRIMARY KEY,
                value BLOB NOT NULL,
                versionStamp INTEGER NOT NULL,
                ttl INTEGER
            )
            """
        guard sqlite3_exec(db, createSQL, nil, nil, nil) == SQLITE_OK else {
            let message = String(cString: sqlite3_errmsg(db))
            throw KVError.serializationFailed("Failed to create table: \(message)")
        }

        // Add TTL column if upgrading from an older schema (silently fails if already exists)
        sqlite3_exec(db, "ALTER TABLE kv ADD COLUMN ttl INTEGER", nil, nil, nil)
        // Index for efficient TTL sweep
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS kv_ttl ON kv(ttl) WHERE ttl IS NOT NULL", nil, nil, nil)

        // Read the current max versionStamp
        var stmt: OpaquePointer?
        var maxVersion: UInt64 = 0
        if sqlite3_prepare_v2(db, "SELECT MAX(versionStamp) FROM kv", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                maxVersion = UInt64(sqlite3_column_int64(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        self.nextVersion = maxVersion + 1

        // Prepare cached statements (TTL-aware: exclude expired rows on read)
        sqlite3_prepare_v2(
            db, "SELECT value, versionStamp FROM kv WHERE key = ? AND (ttl IS NULL OR ttl > unixepoch())",
            -1, &getStmt, nil)
        sqlite3_prepare_v2(
            db, "INSERT OR REPLACE INTO kv (key, value, versionStamp, ttl) VALUES (?, ?, ?, ?)",
            -1, &setStmt, nil)
        sqlite3_prepare_v2(db, "DELETE FROM kv WHERE key = ?", -1, &deleteStmt, nil)
    }

    deinit {
        sqlite3_finalize(getStmt)
        sqlite3_finalize(setStmt)
        sqlite3_finalize(deleteStmt)
        sqlite3_close(db)
    }

    // MARK: - Helpers

    private func locked<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    /// Returns the next version and increments the counter.
    /// Must be called while `lock` is held.
    private func bumpVersion() -> UInt64 {
        let v = nextVersion
        nextVersion += 1
        return v
    }

    static func keyString(_ key: KVKey) -> String {
        key.parts.joined(separator: "/")
    }

    static func keyFromString(_ string: String) -> KVKey {
        KVKey(parts: string.split(separator: "/", omittingEmptySubsequences: false).map(String.init))
    }

    private func bindText(_ stmt: OpaquePointer?, index: Int32, value: String) {
        _ = value.withCString { cString in
            sqlite3_bind_text(stmt, index, cString, Int32(value.utf8.count), sqliteTransientPtr)
        }
    }

    private func readBlob(_ stmt: OpaquePointer?, column: Int32) -> Data {
        let length = Int(sqlite3_column_bytes(stmt, column))
        guard let pointer = sqlite3_column_blob(stmt, column) else { return Data() }
        return Data(bytes: pointer, count: length)
    }

    // MARK: - KVBackend

    public func get(key: KVKey) async throws -> KVEntry? {
        try locked {
            guard let stmt = getStmt else { throw sqliteError("get: no prepared statement") }
            defer {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
            }
            bindText(stmt, index: 1, value: Self.keyString(key))

            guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
            let value = readBlob(stmt, column: 0)
            let version = UInt64(sqlite3_column_int64(stmt, 1))
            return KVEntry(key: key, value: value, versionStamp: version)
        }
    }

    public func set(key: KVKey, value: Data) async throws {
        try await set(key: key, value: value, ttl: nil)
    }

    public func set(key: KVKey, value: Data, ttl: Duration?) async throws {
        try locked {
            guard let stmt = setStmt else { throw sqliteError("set: no prepared statement") }
            defer {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
            }
            let version = bumpVersion()
            bindText(stmt, index: 1, value: Self.keyString(key))
            _ = value.withUnsafeBytes { ptr in
                sqlite3_bind_blob(stmt, 2, ptr.baseAddress, Int32(value.count), sqliteTransientPtr)
            }
            sqlite3_bind_int64(stmt, 3, Int64(version))

            if let ttl {
                let expiresAt = Int64(Date().timeIntervalSince1970) + Int64(ttl.components.seconds)
                sqlite3_bind_int64(stmt, 4, expiresAt)
            } else {
                sqlite3_bind_null(stmt, 4)
            }

            guard sqlite3_step(stmt) == SQLITE_DONE else { throw sqliteError("set step") }
        }
    }

    public func delete(key: KVKey) async throws {
        try locked {
            guard let stmt = deleteStmt else { throw sqliteError("delete: no prepared statement") }
            defer {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
            }
            bindText(stmt, index: 1, value: Self.keyString(key))
            sqlite3_step(stmt)
        }
    }

    public func list(prefix: KVKey, limit: Int) async throws -> [KVEntry] {
        try locked {
            let prefixStr = Self.keyString(prefix)
            let lowerBound = prefixStr
            let upperBound = prefixStr + "\u{FFFF}"

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }

            let sql = "SELECT key, value, versionStamp FROM kv WHERE key >= ? AND key < ? AND (ttl IS NULL OR ttl > unixepoch()) ORDER BY key LIMIT ?"
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("prepare list")
            }
            bindText(stmt, index: 1, value: lowerBound)
            bindText(stmt, index: 2, value: upperBound)
            sqlite3_bind_int(stmt, 3, Int32(limit))

            var entries: [KVEntry] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let keyText = String(cString: sqlite3_column_text(stmt, 0))
                let key = Self.keyFromString(keyText)
                guard key.hasPrefix(KVKey(parts: prefix.parts)) else { continue }
                let value = readBlob(stmt, column: 1)
                let version = UInt64(sqlite3_column_int64(stmt, 2))
                entries.append(KVEntry(key: key, value: value, versionStamp: version))
            }
            return entries
        }
    }

    public func exists(key: KVKey) async throws -> Bool {
        try locked {
            guard let stmt = getStmt else { throw sqliteError("exists: no prepared statement") }
            defer {
                sqlite3_reset(stmt)
                sqlite3_clear_bindings(stmt)
            }
            bindText(stmt, index: 1, value: Self.keyString(key))
            return sqlite3_step(stmt) == SQLITE_ROW
        }
    }

    public func increment(key: KVKey, by delta: Int64) async throws -> Int64 {
        try locked {
            // Use INSERT ... ON CONFLICT for atomic increment
            let sql = """
                INSERT INTO kv (key, value, versionStamp, ttl)
                VALUES (?, CAST(? AS BLOB), ?, NULL)
                ON CONFLICT(key) DO UPDATE SET
                    value = CAST(CAST(value AS INTEGER) + ? AS BLOB),
                    versionStamp = ?
                RETURNING CAST(value AS INTEGER)
                """
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("increment prepare")
            }
            let version = bumpVersion()
            bindText(stmt, index: 1, value: Self.keyString(key))
            sqlite3_bind_int64(stmt, 2, delta)
            sqlite3_bind_int64(stmt, 3, Int64(version))
            sqlite3_bind_int64(stmt, 4, delta)
            sqlite3_bind_int64(stmt, 5, Int64(version))

            guard sqlite3_step(stmt) == SQLITE_ROW else {
                throw sqliteError("increment step")
            }
            return sqlite3_column_int64(stmt, 0)
        }
    }

    public func sweepExpired() async throws {
        try locked {
            guard
                sqlite3_exec(db, "DELETE FROM kv WHERE ttl IS NOT NULL AND ttl <= unixepoch()", nil, nil, nil)
                    == SQLITE_OK
            else {
                throw sqliteError("sweep expired")
            }
        }
    }

    public func commitAtomic(_ operations: [AtomicOp]) async throws {
        try locked {
            guard sqlite3_exec(db, "BEGIN IMMEDIATE", nil, nil, nil) == SQLITE_OK else {
                throw sqliteError("begin transaction")
            }

            do {
                for op in operations {
                    if case .check(let key, let expectedVersion) = op {
                        guard let stmt = getStmt else { throw sqliteError("check: no prepared statement") }
                        defer {
                            sqlite3_reset(stmt)
                            sqlite3_clear_bindings(stmt)
                        }
                        bindText(stmt, index: 1, value: Self.keyString(key))

                        let current: UInt64?
                        if sqlite3_step(stmt) == SQLITE_ROW {
                            current = UInt64(sqlite3_column_int64(stmt, 1))
                        } else {
                            current = nil
                        }
                        if current != expectedVersion {
                            throw KVError.commitConflict(key: key)
                        }
                    }
                }

                for op in operations {
                    switch op {
                    case .set(let key, let value):
                        guard let stmt = setStmt else { throw sqliteError("atomic set: no prepared statement") }
                        defer {
                            sqlite3_reset(stmt)
                            sqlite3_clear_bindings(stmt)
                        }
                        let version = bumpVersion()
                        bindText(stmt, index: 1, value: Self.keyString(key))
                        _ = value.withUnsafeBytes { ptr in
                            sqlite3_bind_blob(stmt, 2, ptr.baseAddress, Int32(value.count), sqliteTransientPtr)
                        }
                        sqlite3_bind_int64(stmt, 3, Int64(version))
                        sqlite3_bind_null(stmt, 4)
                        guard sqlite3_step(stmt) == SQLITE_DONE else { throw sqliteError("atomic set step") }

                    case .setWithTTL(let key, let value, let ttl):
                        guard let stmt = setStmt else { throw sqliteError("atomic setTTL: no prepared statement") }
                        defer {
                            sqlite3_reset(stmt)
                            sqlite3_clear_bindings(stmt)
                        }
                        let version = bumpVersion()
                        bindText(stmt, index: 1, value: Self.keyString(key))
                        _ = value.withUnsafeBytes { ptr in
                            sqlite3_bind_blob(stmt, 2, ptr.baseAddress, Int32(value.count), sqliteTransientPtr)
                        }
                        sqlite3_bind_int64(stmt, 3, Int64(version))
                        let expiresAt = Int64(Date().timeIntervalSince1970) + Int64(ttl.components.seconds)
                        sqlite3_bind_int64(stmt, 4, expiresAt)
                        guard sqlite3_step(stmt) == SQLITE_DONE else { throw sqliteError("atomic setTTL step") }

                    case .delete(let key):
                        guard let stmt = deleteStmt else { throw sqliteError("atomic delete: no prepared statement") }
                        defer {
                            sqlite3_reset(stmt)
                            sqlite3_clear_bindings(stmt)
                        }
                        bindText(stmt, index: 1, value: Self.keyString(key))
                        sqlite3_step(stmt)

                    case .check:
                        break
                    }
                }

                guard sqlite3_exec(db, "COMMIT", nil, nil, nil) == SQLITE_OK else { throw sqliteError("commit") }
            } catch {
                sqlite3_exec(db, "ROLLBACK", nil, nil, nil)
                throw error
            }
        }
    }

    private func sqliteError(_ context: String) -> KVError {
        let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
        return KVError.serializationFailed("SQLite \(context): \(message)")
    }
}
