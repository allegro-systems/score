import Foundation
import SQLite3

/// SQLite transient destructor constant.
private let dbTransientPtr = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A persistent DB backend backed by SQLite.
///
/// Records are stored as JSON blobs in a `data` column with extracted
/// index columns for efficient filtering. Each table has an `id TEXT
/// PRIMARY KEY` and a `data BLOB NOT NULL`, plus any index columns
/// defined by the ``TableDefinition``.
public final class SQLiteDBBackend: DBBackend, @unchecked Sendable {

    private nonisolated(unsafe) static let isoFormatter = ISO8601DateFormatter()

    private var db: OpaquePointer?
    private let lock = NSLock()

    /// Opens or creates a SQLite database at the given path.
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
            throw DBError.serializationFailed("Failed to open database: \(message)")
        }
        self.db = dbPointer
        sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
        sqlite3_exec(db, "PRAGMA foreign_keys=ON", nil, nil, nil)
    }

    deinit {
        sqlite3_close(db)
    }

    private func locked<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    private func exec(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw sqliteError("exec")
        }
    }

    private func bindText(_ stmt: OpaquePointer?, index: Int32, value: String) {
        _ = value.withCString { cString in
            sqlite3_bind_text(stmt, index, cString, Int32(value.utf8.count), dbTransientPtr)
        }
    }

    private func readBlob(_ stmt: OpaquePointer?, column: Int32) -> Data {
        let length = Int(sqlite3_column_bytes(stmt, column))
        guard let pointer = sqlite3_column_blob(stmt, column) else { return Data() }
        return Data(bytes: pointer, count: length)
    }

    private func sqliteError(_ context: String) -> DBError {
        let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
        return DBError.serializationFailed("SQLite \(context): \(message)")
    }

    // MARK: - DBBackend

    public func createTable(name: String, columns: [RawColumn]) throws {
        try locked {
            var columnDefs = [
                "id TEXT PRIMARY KEY",
                "data BLOB NOT NULL",
                "updated_at TEXT NOT NULL DEFAULT (datetime('now'))",
            ]
            for col in columns {
                var def = "\(col.name) \(col.type)"
                if col.unique { def += " UNIQUE" }
                columnDefs.append(def)
            }
            let sql = "CREATE TABLE IF NOT EXISTS \(name) (\(columnDefs.joined(separator: ", ")))"
            try exec(sql)

            // Create indexes for non-unique columns (unique columns already have implicit indexes)
            for col in columns where !col.unique {
                let indexSQL = "CREATE INDEX IF NOT EXISTS idx_\(name)_\(col.name) ON \(name)(\(col.name))"
                try exec(indexSQL)
            }
        }
    }

    public func upsert(table: String, id: String, data: Data, columns: [String: String?]) async throws {
        try locked {
            let colNames = columns.keys.sorted()
            let allCols = ["id", "data", "updated_at"] + colNames
            let placeholders = allCols.map { _ in "?" }
            let updates = (["data", "updated_at"] + colNames).map { "\($0) = excluded.\($0)" }

            let sql = """
                INSERT INTO \(table) (\(allCols.joined(separator: ", ")))
                VALUES (\(placeholders.joined(separator: ", ")))
                ON CONFLICT(id) DO UPDATE SET \(updates.joined(separator: ", "))
                """

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("upsert prepare")
            }

            var idx: Int32 = 1
            bindText(stmt, index: idx, value: id); idx += 1
            _ = data.withUnsafeBytes { ptr in
                sqlite3_bind_blob(stmt, idx, ptr.baseAddress, Int32(data.count), dbTransientPtr)
            }; idx += 1
            bindText(stmt, index: idx, value: Self.isoFormatter.string(from: Date())); idx += 1

            for name in colNames {
                if let value = columns[name] ?? nil {
                    bindText(stmt, index: idx, value: value)
                } else {
                    sqlite3_bind_null(stmt, idx)
                }
                idx += 1
            }

            guard sqlite3_step(stmt) == SQLITE_DONE else { throw sqliteError("upsert step") }
        }
    }

    public func selectOne(table: String, id: String) async throws -> Data? {
        try locked {
            let sql = "SELECT data FROM \(table) WHERE id = ?"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("selectOne prepare")
            }
            bindText(stmt, index: 1, value: id)
            guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
            return readBlob(stmt, column: 0)
        }
    }

    public func selectAll(
        table: String,
        filters: [QueryFilter],
        orderBy: String?,
        ascending: Bool,
        limit: Int?
    ) async throws -> [Data] {
        try locked {
            var sql = "SELECT data FROM \(table)"
            var params: [String] = []

            if !filters.isEmpty {
                let clauses = filters.map { filter -> String in
                    switch filter {
                    case .equals(let column, let value):
                        params.append(value)
                        return "\(column) = ?"
                    case .like(let column, let pattern):
                        params.append(pattern)
                        return "\(column) LIKE ?"
                    }
                }
                sql += " WHERE " + clauses.joined(separator: " AND ")
            }

            if let orderBy {
                sql += " ORDER BY \(orderBy) \(ascending ? "ASC" : "DESC")"
            }
            if let limit {
                sql += " LIMIT \(limit)"
            }

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("selectAll prepare")
            }

            for (i, param) in params.enumerated() {
                bindText(stmt, index: Int32(i + 1), value: param)
            }

            var results: [Data] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                results.append(readBlob(stmt, column: 0))
            }
            return results
        }
    }

    public func selectCount(table: String, filters: [QueryFilter]) async throws -> Int {
        try locked {
            var sql = "SELECT COUNT(*) FROM \(table)"
            var params: [String] = []

            if !filters.isEmpty {
                let clauses = filters.map { filter -> String in
                    switch filter {
                    case .equals(let column, let value):
                        params.append(value)
                        return "\(column) = ?"
                    case .like(let column, let pattern):
                        params.append(pattern)
                        return "\(column) LIKE ?"
                    }
                }
                sql += " WHERE " + clauses.joined(separator: " AND ")
            }

            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("selectCount prepare")
            }

            for (i, param) in params.enumerated() {
                bindText(stmt, index: Int32(i + 1), value: param)
            }

            guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int64(stmt, 0))
        }
    }

    public func deleteOne(table: String, id: String) async throws {
        try locked {
            let sql = "DELETE FROM \(table) WHERE id = ?"
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw sqliteError("deleteOne prepare")
            }
            bindText(stmt, index: 1, value: id)
            sqlite3_step(stmt)
        }
    }
}
