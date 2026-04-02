import Foundation

/// A pluggable storage backend for `DBStore`.
///
/// Implement this protocol to provide custom database engines
/// (e.g., PostgreSQL, MySQL). The built-in ``SQLiteDBBackend``
/// covers most use cases.
public protocol DBBackend: Sendable {

    /// Creates a table with the given name, columns, and constraints.
    func createTable(name: String, columns: [RawColumn]) throws

    /// Inserts or updates a record.
    func upsert(table: String, id: String, data: Data, columns: [String: String?]) async throws

    /// Retrieves a single record by ID.
    func selectOne(table: String, id: String) async throws -> Data?

    /// Queries records with optional filters, ordering, and limits.
    func selectAll(
        table: String,
        filters: [QueryFilter],
        orderBy: String?,
        ascending: Bool,
        limit: Int?
    ) async throws -> [Data]

    /// Counts records matching the given filters.
    func selectCount(table: String, filters: [QueryFilter]) async throws -> Int

    /// Deletes a record by ID.
    func deleteOne(table: String, id: String) async throws
}

/// Describes a column for table creation.
public struct RawColumn: Sendable {
    public let name: String
    public let type: String
    public let unique: Bool

    public init(name: String, type: String, unique: Bool = false) {
        self.name = name
        self.type = type
        self.unique = unique
    }
}

/// A filter condition for queries.
public enum QueryFilter: Sendable {
    case equals(column: String, value: String)
    case like(column: String, pattern: String)
}
