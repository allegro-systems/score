import Foundation

/// A type-safe document store with relational indexing.
///
/// Records are stored as JSON blobs with extracted index columns for
/// efficient queries. This gives the flexibility of document storage
/// with the query power of relational databases.
///
/// Two built-in backends are provided:
///
/// - **`.persistent()`** — SQLite-backed, survives restarts (default)
/// - **`.memory()`** — In-process only, for tests
///
/// ### Example
///
/// ```swift
/// let db = try DBStore.persistent()
/// try db.register(UsersTable.self)
///
/// try await db.save(UsersTable.self, record: user)
/// let user = try await db.get(UsersTable.self, id: "123")
///
/// let admins = try await db.query(UsersTable.self)
///     .where("role", equals: "admin")
///     .orderBy("name")
///     .all()
/// ```
public struct DBStore: Sendable {

    private let backend: any DBBackend

    /// Creates a store backed by the given backend.
    public init(backend: any DBBackend) {
        self.backend = backend
    }

    // MARK: - Factory Methods

    /// Creates a persistent SQLite-backed store.
    ///
    /// - Parameter path: The database file path. Defaults to `.score/data.db`.
    public static func persistent(path: String = ".score/data.db") throws -> DBStore {
        DBStore(backend: try SQLiteDBBackend(path: path))
    }

    /// Creates an in-memory store for tests.
    public static func memory() -> DBStore {
        DBStore(backend: MemoryDBBackend())
    }

    // MARK: - Schema

    /// Registers a table, creating it if it does not exist.
    ///
    /// Call once at startup for each table your app uses.
    public func register<T: TableDefinition>(_ table: T.Type) throws {
        let columns = T.indexes.map { index in
            RawColumn(name: index.name, type: index.type.rawValue, unique: index.unique)
        }
        try backend.createTable(name: T.tableName, columns: columns)
    }

    // MARK: - Save

    /// Saves a record, inserting or updating as needed.
    public func save<T: TableDefinition>(_ table: T.Type, record: T.Record) async throws {
        let id = T.id(for: record)
        let data = try JSONEncoder().encode(record)
        var columns: [String: String?] = [:]
        for index in T.indexes {
            columns[index.name] = index.extract(record)
        }
        try await backend.upsert(table: T.tableName, id: id, data: data, columns: columns)
    }

    // MARK: - Get

    /// Retrieves a record by ID, or `nil` if not found.
    public func get<T: TableDefinition>(_ table: T.Type, id: String) async throws -> T.Record? {
        guard let data = try await backend.selectOne(table: T.tableName, id: id) else { return nil }
        return try JSONDecoder().decode(T.Record.self, from: data)
    }

    // MARK: - Delete

    /// Deletes a record by ID.
    public func delete<T: TableDefinition>(_ table: T.Type, id: String) async throws {
        try await backend.deleteOne(table: T.tableName, id: id)
    }

    // MARK: - Query

    /// Creates a query builder for the given table.
    public func query<T: TableDefinition>(_ table: T.Type) -> Query<T> {
        Query<T>(backend: backend)
    }
}
