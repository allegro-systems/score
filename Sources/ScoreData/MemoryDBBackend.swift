import Foundation

/// An in-memory DB backend for tests.
///
/// Data lives only in process memory and is lost when the process exits.
public final class MemoryDBBackend: DBBackend, @unchecked Sendable {

    private var tables: [String: [String: StoredRow]] = [:]
    private let lock = NSLock()

    private struct StoredRow {
        let id: String
        let data: Data
        var columns: [String: String?]
    }

    public init() {}

    private func locked<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }

    public func createTable(name: String, columns: [RawColumn]) throws {
        try locked {
            if tables[name] == nil {
                tables[name] = [:]
            }
        }
    }

    public func upsert(table: String, id: String, data: Data, columns: [String: String?]) async throws {
        try locked {
            guard tables[table] != nil else {
                throw DBError.tableNotRegistered(table)
            }
            tables[table]![id] = StoredRow(id: id, data: data, columns: columns)
        }
    }

    public func selectOne(table: String, id: String) async throws -> Data? {
        try locked {
            guard let rows = tables[table] else {
                throw DBError.tableNotRegistered(table)
            }
            return rows[id]?.data
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
            guard let rows = tables[table] else {
                throw DBError.tableNotRegistered(table)
            }

            var results = Array(rows.values)

            for filter in filters {
                switch filter {
                case .equals(let column, let value):
                    results = results.filter { ($0.columns[column] ?? nil) == value }
                case .like(let column, let pattern):
                    let regex = pattern.replacingOccurrences(of: "%", with: ".*")
                    results = results.filter { row in
                        guard let val = row.columns[column] ?? nil else { return false }
                        return val.range(of: "^\(regex)$", options: .regularExpression) != nil
                    }
                }
            }

            if let orderBy {
                results.sort { a, b in
                    let aVal = (a.columns[orderBy] ?? nil) ?? ""
                    let bVal = (b.columns[orderBy] ?? nil) ?? ""
                    return ascending ? aVal < bVal : aVal > bVal
                }
            }

            if let limit {
                results = Array(results.prefix(limit))
            }

            return results.map(\.data)
        }
    }

    public func selectCount(table: String, filters: [QueryFilter]) async throws -> Int {
        let rows = try await selectAll(table: table, filters: filters, orderBy: nil, ascending: true, limit: nil)
        return rows.count
    }

    public func deleteOne(table: String, id: String) async throws {
        try locked {
            guard tables[table] != nil else {
                throw DBError.tableNotRegistered(table)
            }
            tables[table]![id] = nil
        }
    }
}
