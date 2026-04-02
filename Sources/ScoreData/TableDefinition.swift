import Foundation

/// Defines a typed database table that stores `Codable` records as JSON
/// with extracted columns for indexing and querying.
///
/// Records are stored as JSON blobs with an `id` primary key. Additional
/// columns can be extracted from the record via ``indexes`` for efficient
/// filtering and ordering.
///
/// ### Example
///
/// ```swift
/// struct AppsTable: TableDefinition {
///     typealias Record = DeployedApp
///     static let tableName = "apps"
///     static let indexes: [IndexColumn<DeployedApp>] = [
///         .text("user") { $0.user },
///     ]
/// }
/// ```
public protocol TableDefinition: Sendable {
    /// The record type stored in this table.
    associatedtype Record: Codable & Sendable

    /// The table name in the database.
    static var tableName: String { get }

    /// Index columns extracted from the record for efficient queries.
    static var indexes: [IndexColumn<Record>] { get }

    /// Extracts the primary key from a record.
    static func id(for record: Record) -> String
}

/// An extracted column used for indexing and filtering.
///
/// Define index columns on your ``TableDefinition`` to enable efficient
/// queries via ``Query``. Each index column maps to a real database column
/// alongside the `id` and `data` blob.
///
/// ```swift
/// static let indexes: [IndexColumn<User>] = [
///     .text("email", unique: true) { $0.email },
///     .text("name") { $0.name },
///     .integer("age") { $0.age },
/// ]
/// ```
public struct IndexColumn<Record: Codable & Sendable>: Sendable {

    /// The column name in the database.
    public let name: String

    /// The SQL type of this column.
    public let type: ColumnType

    /// Whether this column has a unique constraint.
    public let unique: Bool

    /// Extracts the column value from a record as a string, or `nil` if absent.
    public let extract: @Sendable (Record) -> String?

    /// SQL column types.
    public enum ColumnType: String, Sendable {
        case text = "TEXT"
        case integer = "INTEGER"
        case real = "REAL"
    }

    /// Creates a text index column.
    public static func text(
        _ name: String,
        unique: Bool = false,
        _ extract: @escaping @Sendable (Record) -> String?
    ) -> IndexColumn<Record> {
        IndexColumn(name: name, type: .text, unique: unique, extract: extract)
    }

    /// Creates an integer index column.
    public static func integer(
        _ name: String,
        unique: Bool = false,
        _ extract: @escaping @Sendable (Record) -> Int?
    ) -> IndexColumn<Record> {
        IndexColumn(name: name, type: .integer, unique: unique, extract: { record in
            extract(record).map { "\($0)" }
        })
    }

    /// Creates a real (floating point) index column.
    public static func real(
        _ name: String,
        unique: Bool = false,
        _ extract: @escaping @Sendable (Record) -> Double?
    ) -> IndexColumn<Record> {
        IndexColumn(name: name, type: .real, unique: unique, extract: { record in
            extract(record).map { "\($0)" }
        })
    }
}
