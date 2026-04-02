import Foundation

/// A type-safe, chainable query builder for ``DBStore``.
///
/// Build queries by chaining filter, ordering, and limit methods,
/// then execute with ``all()``, ``first()``, or ``count()``.
///
/// ```swift
/// let users = try await db.query(UsersTable.self)
///     .where("name", equals: "Alice")
///     .orderBy("created_at", ascending: false)
///     .limit(10)
///     .all()
/// ```
public struct Query<T: TableDefinition>: Sendable {

    let backend: any DBBackend
    var filters: [QueryFilter] = []
    var orderColumn: String?
    var orderAscending: Bool = true
    var resultLimit: Int?

    init(backend: any DBBackend) {
        self.backend = backend
    }

    /// Filters records where `column` equals `value`.
    public func `where`(_ column: String, equals value: String) -> Query<T> {
        var copy = self
        copy.filters.append(.equals(column: column, value: value))
        return copy
    }

    /// Filters records where `column` matches `pattern` (SQL LIKE).
    public func `where`(_ column: String, like pattern: String) -> Query<T> {
        var copy = self
        copy.filters.append(.like(column: column, pattern: pattern))
        return copy
    }

    /// Sets the ordering column and direction.
    public func orderBy(_ column: String, ascending: Bool = true) -> Query<T> {
        var copy = self
        copy.orderColumn = column
        copy.orderAscending = ascending
        return copy
    }

    /// Limits the number of returned records.
    public func limit(_ count: Int) -> Query<T> {
        var copy = self
        copy.resultLimit = count
        return copy
    }

    /// Executes the query and returns all matching records.
    public func all() async throws -> [T.Record] {
        let rows = try await backend.selectAll(
            table: T.tableName,
            filters: filters,
            orderBy: orderColumn,
            ascending: orderAscending,
            limit: resultLimit
        )
        return try rows.map { try JSONDecoder().decode(T.Record.self, from: $0) }
    }

    /// Executes the query and returns the first matching record.
    public func first() async throws -> T.Record? {
        var limited = self
        limited.resultLimit = 1
        let results = try await limited.all()
        return results.first
    }

    /// Executes the query and returns the count of matching records.
    public func count() async throws -> Int {
        try await backend.selectCount(table: T.tableName, filters: filters)
    }
}
