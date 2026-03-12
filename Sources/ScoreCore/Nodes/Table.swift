/// A node that renders a structured grid of data arranged in rows and columns.
///
/// `Table` renders as the HTML `<table>` element. It serves as the root
/// container for all other table-related nodes: ``TableCaption``,
/// ``TableHead``, ``TableBody``, ``TableFooter``, ``TableColumnGroup``, and
/// their descendants.
///
/// Typical uses include:
/// - Displaying financial or statistical datasets
/// - Comparing product features across multiple options
/// - Presenting scheduling or timetable information
///
/// ### Example
///
/// ```swift
/// Table {
///     TableCaption { "Q1 Sales Summary" }
///     TableHead {
///         TableRow {
///             TableHeaderCell(scope: .column) { "Region" }
///             TableHeaderCell(scope: .column) { "Revenue" }
///         }
///     }
///     TableBody {
///         TableRow {
///             TableCell { "North" }
///             TableCell { "$120,000" }
///         }
///         TableRow {
///             TableCell { "South" }
///             TableCell { "$98,500" }
///         }
///     }
/// }
/// ```
///
/// - Important: Only use `Table` for genuinely tabular data. Using tables for
///   layout purposes is an accessibility anti-pattern and will mislead screen
///   reader users.
public struct Table<Content: Node>: Node, SourceLocatable {

    /// The child nodes that make up the table, such as ``TableCaption``,
    /// ``TableHead``, ``TableBody``, and ``TableFooter``.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a visible title or description for a ``Table``.
///
/// `TableCaption` renders as the HTML `<caption>` element. It must be placed
/// as the first child of a ``Table`` and provides an accessible name for the
/// table that is announced by screen readers before the table data.
///
/// ### Example
///
/// ```swift
/// Table {
///     TableCaption { "Monthly Visitor Statistics" }
///     TableBody {
///         TableRow {
///             TableCell { "January" }
///             TableCell { "4,200" }
///         }
///     }
/// }
/// ```
///
/// - Important: Always include a `TableCaption` to help users of assistive
///   technologies understand the purpose of the table before navigating its
///   cells.
public struct TableCaption<Content: Node>: Node, SourceLocatable {

    /// The caption text or inline content that titles the table.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table caption.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that groups the header rows of a ``Table``.
///
/// `TableHead` renders as the HTML `<thead>` element. It wraps one or more
/// ``TableRow`` nodes that contain column headings, typically using
/// ``TableHeaderCell`` cells. Browsers may repeat the header across pages when
/// printing long tables.
///
/// ### Example
///
/// ```swift
/// TableHead {
///     TableRow {
///         TableHeaderCell(scope: .column) { "Name" }
///         TableHeaderCell(scope: .column) { "Score" }
///     }
/// }
/// ```
public struct TableHead<Content: Node>: Node, SourceLocatable {

    /// The ``TableRow`` children that form the table's header section.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table head section.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that groups the main data rows of a ``Table``.
///
/// `TableBody` renders as the HTML `<tbody>` element. It wraps the primary
/// data ``TableRow`` nodes and can appear multiple times in a single table to
/// create logical row groupings with independent styling or semantics.
///
/// ### Example
///
/// ```swift
/// TableBody {
///     TableRow {
///         TableCell { "Alice" }
///         TableCell { "95" }
///     }
///     TableRow {
///         TableCell { "Bob" }
///         TableCell { "87" }
///     }
/// }
/// ```
public struct TableBody<Content: Node>: Node, SourceLocatable {

    /// The ``TableRow`` children that form the table's body section.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table body section.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that groups the footer rows of a ``Table``.
///
/// `TableFooter` renders as the HTML `<tfoot>` element. It wraps summary or
/// totals rows that appear at the bottom of the table. Like ``TableHead``,
/// browsers may repeat footer rows across printed pages.
///
/// ### Example
///
/// ```swift
/// TableFooter {
///     TableRow {
///         TableHeaderCell(scope: .row) { "Total" }
///         TableCell { "$218,500" }
///     }
/// }
/// ```
public struct TableFooter<Content: Node>: Node, SourceLocatable {

    /// The ``TableRow`` children that form the table's footer section.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table footer section.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a single horizontal row of cells within a ``Table``.
///
/// `TableRow` renders as the HTML `<tr>` element. It contains ``TableCell``
/// and/or ``TableHeaderCell`` children and must be nested inside
/// ``TableHead``, ``TableBody``, or ``TableFooter``.
///
/// ### Example
///
/// ```swift
/// TableRow {
///     TableHeaderCell(scope: .row) { "Alice" }
///     TableCell { "42" }
///     TableCell { "98 %" }
/// }
/// ```
public struct TableRow<Content: Node>: Node, SourceLocatable {

    /// The ``TableCell`` and/or ``TableHeaderCell`` children that fill this row.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table row.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// Defines the axis of cells that a ``TableHeaderCell`` applies to.
///
/// `TableHeaderScope` maps directly to the values of the HTML `scope`
/// attribute on a `<th>` element. Screen readers use this value to correctly
/// associate data cells with their headers when navigating a table
/// non-visually.
public enum TableHeaderScope: String, Sendable {

    /// The header applies to all cells in the same row.
    ///
    /// Corresponds to the HTML value `"row"`.
    case row

    /// The header applies to all cells in the same column.
    ///
    /// Corresponds to the HTML value `"col"`.
    case column = "col"

    /// The header applies to all cells in the remaining rows of the row group
    /// (i.e. the enclosing ``TableHead``, ``TableBody``, or ``TableFooter``).
    ///
    /// Corresponds to the HTML value `"rowgroup"`.
    case rowGroup = "rowgroup"

    /// The header applies to all cells in the remaining columns of the column
    /// group (i.e. the enclosing ``TableColumnGroup``).
    ///
    /// Corresponds to the HTML value `"colgroup"`.
    case columnGroup = "colgroup"
}

/// A node that renders a header cell within a ``TableRow``.
///
/// `TableHeaderCell` renders as the HTML `<th>` element. Header cells convey
/// the meaning of a column or row to both sighted users and assistive
/// technologies. Providing a `scope` value is strongly recommended to
/// explicitly associate the header with the correct axis of data cells.
///
/// ### Example
///
/// ```swift
/// TableRow {
///     TableHeaderCell(scope: .column) { "Product" }
///     TableHeaderCell(scope: .column) { "Price" }
///     TableHeaderCell(scope: .column) { "In Stock" }
/// }
/// ```
public struct TableHeaderCell<Content: Node>: Node, SourceLocatable {

    /// The axis of data cells this header applies to.
    ///
    /// Rendered as the HTML `scope` attribute. When `nil`, no `scope`
    /// attribute is rendered and the browser infers the association
    /// heuristically.
    public let scope: TableHeaderScope?

    /// The heading text or content rendered inside the `<th>` element.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table header cell.
    public init(
        scope: TableHeaderScope? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.scope = scope
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a standard data cell within a ``TableRow``.
///
/// `TableCell` renders as the HTML `<td>` element. It holds the actual data
/// content of the table and is distinguished from ``TableHeaderCell`` which
/// carries semantic heading information.
///
/// ### Example
///
/// ```swift
/// TableRow {
///     TableCell { "MacBook Pro" }
///     TableCell { "$2,499" }
///     TableCell { "Yes" }
/// }
/// ```
public struct TableCell<Content: Node>: Node, SourceLocatable {

    /// The data content rendered inside the `<td>` element.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a table data cell.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that groups one or more columns in a ``Table`` to allow shared
/// styling or a spanning header.
///
/// `TableColumnGroup` renders as the HTML `<colgroup>` element. When a `span`
/// is provided, the group encompasses that many consecutive columns without
/// requiring individual ``TableColumn`` children. When child ``TableColumn``
/// nodes are provided, each one can carry its own `span` for finer-grained
/// grouping.
///
/// ### Example
///
/// ```swift
/// Table {
///     TableColumnGroup(span: 2)   // spans first two columns
///     TableColumnGroup {
///         TableColumn(span: 1)    // third column
///         TableColumn(span: 2)    // fourth and fifth columns
///     }
///     TableBody {
///         // rows …
///     }
/// }
/// ```
///
/// - Important: `TableColumnGroup` and ``TableColumn`` do not render visible
///   content; they exist purely to carry CSS classes or styles that are
///   applied to the grouped columns.
public struct TableColumnGroup<Content: Node>: Node, SourceLocatable {

    /// The number of consecutive table columns this group spans.
    ///
    /// Rendered as the HTML `span` attribute when no ``TableColumn`` children
    /// are present. If `nil`, the group's extent is determined by its child
    /// ``TableColumn`` nodes.
    public let span: Int?

    /// Optional ``TableColumn`` children that further subdivide the group.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a column group.
    public init(
        span: Int? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.span = span
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that represents a single column or a span of columns within a
/// ``TableColumnGroup``.
///
/// `TableColumn` renders as the HTML `<col>` element. It is a void element —
/// it carries no content — and is used exclusively to target one or more
/// columns with CSS styling through a class or style attribute applied at the
/// Score modifier level.
///
/// ### Example
///
/// ```swift
/// TableColumnGroup {
///     TableColumn(span: 1)  // first column
///     TableColumn(span: 2)  // next two columns share the same styling
/// }
/// ```
public struct TableColumn: Node, SourceLocatable {

    /// The number of consecutive columns this element represents.
    ///
    /// Rendered as the HTML `span` attribute. If `nil`, the element applies to
    /// exactly one column (the browser default).
    public let span: Int?
    public let sourceLocation: SourceLocation

    /// Creates a column descriptor.
    public init(span: Int? = nil, file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        self.span = span
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}
