import ScoreCore

/// A column definition for a ``DataTable``.
///
/// ### Example
///
/// ```swift
/// DataColumn(header: "Name")
/// DataColumn(header: "Email")
/// ```
public struct DataColumn: Sendable {

    /// The header text for this column.
    public let header: String

    /// Creates a column definition.
    ///
    /// - Parameter header: The column header text.
    public init(header: String) {
        self.header = header
    }
}

/// A high-level data table component with column definitions.
///
/// `DataTable` wraps the core ``Table`` node and accepts column
/// definitions and row content, generating the header automatically.
///
/// ### Example
///
/// ```swift
/// DataTable(
///     columns: [
///         DataColumn(header: "Name"),
///         DataColumn(header: "Role"),
///     ]
/// ) {
///     TableRow {
///         TableCell { "Alice" }
///         TableCell { "Engineer" }
///     }
///     TableRow {
///         TableCell { "Bob" }
///         TableCell { "Designer" }
///     }
/// }
/// ```
public struct DataTable<Content: Node>: Component {

    /// The column definitions that generate the table header.
    public let columns: [DataColumn]

    /// An optional table caption for accessibility.
    public let caption: String?

    /// The table body rows.
    public let content: Content

    /// Creates a data table.
    ///
    /// - Parameters:
    ///   - columns: The column definitions.
    ///   - caption: An optional accessible caption. Defaults to `nil`.
    ///   - content: A `@NodeBuilder` closure providing ``TableRow`` children.
    public init(
        columns: [DataColumn],
        caption: String? = nil,
        @NodeBuilder content: () -> Content
    ) {
        self.columns = columns
        self.caption = caption
        self.content = content()
    }

    public var body: some Node {
        Table {
            if let caption {
                TableCaption { Text(verbatim: caption) }
            }
            TableHead {
                TableRow {
                    ForEachNode(columns) { column in
                        TableHeaderCell(scope: .column) {
                            Text(verbatim: column.header)
                        }
                    }
                }
            }
            .htmlAttribute("data-part", "header")
            TableBody {
                content
            }
            .htmlAttribute("data-part", "body")
        }
        .htmlAttribute("data-component", "table")
        .border(width: 1, color: .border, style: .solid)
    }
}
