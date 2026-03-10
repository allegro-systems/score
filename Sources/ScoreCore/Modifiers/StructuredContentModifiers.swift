/// The visual marker type rendered alongside list items.
///
/// `ListStyleType` controls the kind of bullet or numbering applied to list items,
/// from simple geometric shapes to alphabetic and Roman numeral sequences.
///
/// ### CSS Mapping
///
/// Maps to the CSS `list-style-type` property.
public enum ListStyleType: String, Sendable {
    /// No marker is displayed.
    ///
    /// CSS equivalent: `list-style-type: none`.
    case none

    /// A filled circle bullet, the default for unordered lists.
    ///
    /// CSS equivalent: `list-style-type: disc`.
    case disc

    /// An open circle bullet.
    ///
    /// CSS equivalent: `list-style-type: circle`.
    case circle

    /// A filled square bullet.
    ///
    /// CSS equivalent: `list-style-type: square`.
    case square

    /// Decimal numbers (1, 2, 3, ...).
    ///
    /// CSS equivalent: `list-style-type: decimal`.
    case decimal

    /// Lowercase Roman numerals (i, ii, iii, ...).
    ///
    /// CSS equivalent: `list-style-type: lower-roman`.
    case lowerRoman = "lower-roman"

    /// Uppercase Roman numerals (I, II, III, ...).
    ///
    /// CSS equivalent: `list-style-type: upper-roman`.
    case upperRoman = "upper-roman"

    /// Lowercase ASCII letters (a, b, c, ...).
    ///
    /// CSS equivalent: `list-style-type: lower-alpha`.
    case lowerAlpha = "lower-alpha"

    /// Uppercase ASCII letters (A, B, C, ...).
    ///
    /// CSS equivalent: `list-style-type: upper-alpha`.
    case upperAlpha = "upper-alpha"
}

/// The position of the list item marker relative to the list item's content box.
///
/// `ListStylePosition` controls whether the marker is placed inside or outside
/// the content flow of the list item.
///
/// ### CSS Mapping
///
/// Maps to the CSS `list-style-position` property.
public enum ListStylePosition: String, Sendable {
    /// The marker is placed inside the content box, flowing with the text.
    ///
    /// CSS equivalent: `list-style-position: inside`.
    case inside

    /// The marker is placed outside the content box, to the left of the list item.
    ///
    /// CSS equivalent: `list-style-position: outside`.
    case outside
}

/// A modifier that configures the visual style of a list node.
///
/// `ListStyleModifier` controls the marker type and marker position.
/// All properties are optional; provide only the values you want to override.
///
/// ### Example
///
/// ```swift
/// UnorderedList {
///     ListItem("Apples")
///     ListItem("Oranges")
/// }
/// .listStyle(type: .disc, position: .outside)
///
/// OrderedList {
///     ListItem("Step one")
///     ListItem("Step two")
/// }
/// .listStyle(type: .decimal, position: .inside)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `list-style-type` and `list-style-position`
/// properties on the rendered element.
public struct ListStyleModifier: ModifierValue {
    /// The visual marker type for list items.
    ///
    /// When `nil`, the marker type is inherited from the parent node or browser default.
    public let type: ListStyleType?

    /// The position of the list item marker relative to the content box.
    ///
    /// When `nil`, the position is inherited from the parent node.
    public let position: ListStylePosition?

    /// Creates a list style modifier.
    ///
    /// - Parameters:
    ///   - type: Optional marker type for list items.
    ///   - position: Optional marker position relative to the content box.
    public init(type: ListStyleType? = nil, position: ListStylePosition? = nil) {
        self.type = type
        self.position = position
    }
}

/// The algorithm used to determine the width of table columns.
///
/// `TableLayoutMode` controls whether column widths are calculated based on
/// content (automatic) or on explicit values set for the first row (fixed).
///
/// ### CSS Mapping
///
/// Maps to the CSS `table-layout` property.
public enum TableLayoutMode: String, Sendable {
    /// Column widths are calculated based on the content of all cells.
    ///
    /// CSS equivalent: `table-layout: auto`.
    case auto

    /// Column widths are determined by the widths of the first row's cells,
    /// allowing faster rendering for large tables.
    ///
    /// CSS equivalent: `table-layout: fixed`.
    case fixed
}

/// Whether adjacent table cell borders are merged into a single border or kept separate.
///
/// `BorderCollapseMode` controls the CSS `border-collapse` property, affecting
/// how borders between table cells are rendered.
///
/// ### CSS Mapping
///
/// Maps to the CSS `border-collapse` property.
public enum BorderCollapseMode: String, Sendable {
    /// Adjacent cell borders are rendered separately, with spacing between them.
    ///
    /// CSS equivalent: `border-collapse: separate`.
    case separate

    /// Adjacent cell borders are merged into a single shared border.
    ///
    /// CSS equivalent: `border-collapse: collapse`.
    case collapse
}

/// The vertical position where a table's caption is rendered.
///
/// `CaptionSide` controls whether the `<caption>` element appears above or below
/// the table's content.
///
/// ### CSS Mapping
///
/// Maps to the CSS `caption-side` property.
public enum CaptionSide: String, Sendable {
    /// The caption is placed above the table.
    ///
    /// CSS equivalent: `caption-side: top`.
    case top

    /// The caption is placed below the table.
    ///
    /// CSS equivalent: `caption-side: bottom`.
    case bottom
}

/// A modifier that configures the visual layout of a table node.
///
/// `TableStyleModifier` controls the table's column-sizing algorithm, border
/// collapse mode, cell spacing, and caption position. All properties are optional;
/// provide only the values you want to override.
///
/// ### Example
///
/// ```swift
/// Table {
///     // rows and cells
/// }
/// .tableStyle(layout: .fixed, borderCollapse: .collapse)
///
/// DataGrid()
///     .tableStyle(
///         layout: .auto,
///         borderCollapse: .separate,
///         borderSpacing: 4,
///         captionSide: .bottom
///     )
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `table-layout`, `border-collapse`, `border-spacing`, and
/// `caption-side` properties on the rendered element.
public struct TableStyleModifier: ModifierValue {
    /// The column-sizing algorithm for the table.
    ///
    /// When `nil`, the browser's default (`auto`) is used.
    public let layout: TableLayoutMode?

    /// Whether adjacent cell borders are merged or kept separate.
    ///
    /// When `nil`, the browser's default (`separate`) is used.
    public let borderCollapse: BorderCollapseMode?

    /// The gap in points between adjacent table cells when `borderCollapse` is `.separate`.
    ///
    /// When `nil`, no explicit spacing is set and the browser's default applies.
    public let borderSpacing: Double?

    /// The vertical position of the table's caption element.
    ///
    /// When `nil`, the browser's default (`top`) is used.
    public let captionSide: CaptionSide?

    /// Creates a table style modifier.
    ///
    /// - Parameters:
    ///   - layout: Optional column-sizing algorithm.
    ///   - borderCollapse: Optional border collapse mode.
    ///   - borderSpacing: Optional cell spacing in points.
    ///   - captionSide: Optional caption position.
    public init(layout: TableLayoutMode? = nil, borderCollapse: BorderCollapseMode? = nil, borderSpacing: Double? = nil, captionSide: CaptionSide? = nil) {
        self.layout = layout
        self.borderCollapse = borderCollapse
        self.borderSpacing = borderSpacing
        self.captionSide = captionSide
    }
}

extension Node {
    /// Applies list styling to this node.
    ///
    /// Use this modifier on list nodes to configure the marker type and
    /// marker position.
    ///
    /// ### Example
    ///
    /// ```swift
    /// UnorderedList {
    ///     ListItem("First item")
    ///     ListItem("Second item")
    /// }
    /// .listStyle(type: .disc, position: .outside)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `list-style-type` and `list-style-position`
    /// properties on the rendered element.
    ///
    /// - Parameters:
    ///   - type: Optional marker type for list items.
    ///   - position: Optional marker position relative to the content box.
    /// - Returns: A `ModifiedNode` with the list style modifier applied.
    public func listStyle(type: ListStyleType? = nil, position: ListStylePosition? = nil) -> ModifiedNode<Self> {
        let mod = ListStyleModifier(type: type, position: position)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Applies table layout styling to this node.
    ///
    /// Use this modifier on table nodes to configure the column-sizing algorithm,
    /// border collapse behavior, cell spacing, and caption position.
    ///
    /// ### Example
    ///
    /// ```swift
    /// DataTable()
    ///     .tableStyle(layout: .fixed, borderCollapse: .collapse)
    ///
    /// PricingTable()
    ///     .tableStyle(
    ///         layout: .auto,
    ///         borderCollapse: .separate,
    ///         borderSpacing: 8,
    ///         captionSide: .bottom
    ///     )
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `table-layout`, `border-collapse`, `border-spacing`, and
    /// `caption-side` properties on the rendered element.
    ///
    /// - Parameters:
    ///   - layout: Optional column-sizing algorithm.
    ///   - borderCollapse: Optional border collapse mode.
    ///   - borderSpacing: Optional cell spacing in points.
    ///   - captionSide: Optional caption position.
    /// - Returns: A `ModifiedNode` with the table style modifier applied.
    public func tableStyle(layout: TableLayoutMode? = nil, borderCollapse: BorderCollapseMode? = nil, borderSpacing: Double? = nil, captionSide: CaptionSide? = nil)
        -> ModifiedNode<Self>
    {
        let mod = TableStyleModifier(layout: layout, borderCollapse: borderCollapse, borderSpacing: borderSpacing, captionSide: captionSide)
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
