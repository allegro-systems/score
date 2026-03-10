/// A modifier that controls how a flex item grows, shrinks, and is ordered within its container.
///
/// `FlexItemModifier` applies flex child properties to a node, giving fine-grained
/// control over how an individual item behaves inside a flex container. It covers
/// the `flex-grow`, `flex-shrink`, `flex-basis`, `order`, and `align-self` CSS properties.
///
/// ### Example
///
/// ```swift
/// Div {
///     Text("Grows to fill space")
/// }
/// .flexItem(grow: 1, shrink: 0, alignSelf: .center)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `flex-grow`, `flex-shrink`, `flex-basis`, `order`,
/// and `align-self` properties on the rendered element.
public struct FlexItemModifier: ModifierValue {

    /// The factor by which the item grows relative to other flex siblings.
    ///
    /// A value of `1` allows the item to grow to fill available space.
    /// When `nil`, the CSS `flex-grow` property is not set.
    /// Equivalent to CSS `flex-grow`.
    public let grow: Double?

    /// The factor by which the item shrinks relative to other flex siblings when space is limited.
    ///
    /// A value of `0` prevents the item from shrinking.
    /// When `nil`, the CSS `flex-shrink` property is not set.
    /// Equivalent to CSS `flex-shrink`.
    public let shrink: Double?

    /// The initial main-size of the flex item before free space is distributed.
    ///
    /// Expressed in points. When `nil`, the CSS `flex-basis` property is not set.
    /// Equivalent to CSS `flex-basis`.
    public let basis: Double?

    /// The position of the item relative to other flex siblings.
    ///
    /// Lower values appear first. When `nil`, the CSS `order` property is not set.
    /// Equivalent to CSS `order`.
    public let order: Int?

    /// The cross-axis alignment override for this individual flex item.
    ///
    /// Overrides the container's `align-items` value for this specific child.
    /// When `nil`, the CSS `align-self` property is not set.
    /// Equivalent to CSS `align-self`.
    public let alignSelf: FlexAlign?

    /// Creates a flex item modifier.
    ///
    /// All parameters are optional. Omit any parameter to leave its corresponding
    /// CSS property unset.
    ///
    /// - Parameters:
    ///   - grow: The flex-grow factor. Defaults to `nil`.
    ///   - shrink: The flex-shrink factor. Defaults to `nil`.
    ///   - basis: The flex-basis value in points. Defaults to `nil`.
    ///   - order: The visual ordering index. Defaults to `nil`.
    ///   - alignSelf: The per-item cross-axis alignment. Defaults to `nil`.
    public init(grow: Double? = nil, shrink: Double? = nil, basis: Double? = nil, order: Int? = nil, alignSelf: FlexAlign? = nil) {
        self.grow = grow
        self.shrink = shrink
        self.basis = basis
        self.order = order
        self.alignSelf = alignSelf
    }
}

/// A column or row placement within a CSS grid container.
///
/// `GridSpan` describes where a grid item starts and how many tracks it spans.
///
/// ### CSS Mapping
///
/// Maps to the CSS `grid-column` or `grid-row` property values.
public struct GridSpan: Sendable {

    /// The CSS string representation of this grid span.
    public let cssValue: String

    /// Places the item at a specific grid line.
    ///
    /// - Parameter line: The 1-based grid line number.
    /// - Returns: A grid span starting at the given line.
    public static func line(_ line: Int) -> GridSpan {
        GridSpan(cssValue: "\(line)")
    }

    /// Makes the item span a number of tracks from its auto-placed position.
    ///
    /// - Parameter count: The number of tracks to span.
    /// - Returns: A grid span covering the given number of tracks.
    public static func span(_ count: Int) -> GridSpan {
        GridSpan(cssValue: "span \(count)")
    }

    /// Places the item between two grid lines.
    ///
    /// - Parameters:
    ///   - start: The 1-based starting grid line.
    ///   - end: The 1-based ending grid line.
    /// - Returns: A grid span from `start` to `end`.
    public static func range(_ start: Int, _ end: Int) -> GridSpan {
        GridSpan(cssValue: "\(start) / \(end)")
    }
}

/// A modifier that controls where a grid item is placed within its grid container.
///
/// `GridPlacementModifier` applies grid child placement properties to a node,
/// including explicit column and row placement, named area assignment, and
/// inline justification.
///
/// ### Example
///
/// ```swift
/// Div {
///     Text("Header")
/// }
/// .gridPlacement(area: "header", justifySelf: .center)
///
/// Div {
///     Text("Spanning")
/// }
/// .gridPlacement(column: .range(1, 3), row: .line(1))
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `grid-column`, `grid-row`, `grid-area`, and `justify-self`
/// properties on the rendered element.
public struct GridPlacementModifier: ModifierValue {

    /// The column track or span within the grid.
    ///
    /// When `nil`, the CSS `grid-column` property is not set.
    public let column: GridSpan?

    /// The row track or span within the grid.
    ///
    /// When `nil`, the CSS `grid-row` property is not set.
    public let row: GridSpan?

    /// The named grid area this item should occupy.
    ///
    /// Corresponds to a name defined in the container's `grid-template-areas`.
    /// When `nil`, the CSS `grid-area` property is not set.
    public let area: String?

    /// The inline-axis alignment of the item within its grid cell.
    ///
    /// Overrides the container's `justify-items` value for this specific child.
    /// When `nil`, the CSS `justify-self` property is not set.
    public let justifySelf: TextAlign?

    /// Creates a grid placement modifier.
    ///
    /// All parameters are optional. Omit any parameter to leave its corresponding
    /// CSS property unset.
    ///
    /// - Parameters:
    ///   - column: The grid column placement. Defaults to `nil`.
    ///   - row: The grid row placement. Defaults to `nil`.
    ///   - area: The named grid area. Defaults to `nil`.
    ///   - justifySelf: The inline-axis alignment. Defaults to `nil`.
    public init(column: GridSpan? = nil, row: GridSpan? = nil, area: String? = nil, justifySelf: TextAlign? = nil) {
        self.column = column
        self.row = row
        self.area = area
        self.justifySelf = justifySelf
    }
}

extension Node {

    /// Applies flex item properties to control how the node behaves inside a flex container.
    ///
    /// Use this modifier on children of a `.flex(...)` container to individually
    /// control growth, shrinkage, initial size, visual order, and cross-axis alignment.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     Text("Sidebar")
    /// }
    /// .flexItem(grow: 0, shrink: 0, basis: 240)
    ///
    /// Div {
    ///     Text("Main content")
    /// }
    /// .flexItem(grow: 1)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `flex-grow`, `flex-shrink`, `flex-basis`, `order`,
    /// and `align-self` properties.
    ///
    /// - Parameters:
    ///   - grow: The flex-grow factor. Defaults to `nil`.
    ///   - shrink: The flex-shrink factor. Defaults to `nil`.
    ///   - basis: The flex-basis value in points. Defaults to `nil`.
    ///   - order: The visual ordering index. Defaults to `nil`.
    ///   - alignSelf: The per-item cross-axis alignment. Defaults to `nil`.
    /// - Returns: A modified node with the flex item styles applied.
    public func flexItem(grow: Double? = nil, shrink: Double? = nil, basis: Double? = nil, order: Int? = nil, alignSelf: FlexAlign? = nil) -> ModifiedNode<Self> {
        let mod = FlexItemModifier(grow: grow, shrink: shrink, basis: basis, order: order, alignSelf: alignSelf)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Applies grid placement properties to control where the node appears in a grid container.
    ///
    /// Use this modifier on children of a `.grid(...)` container to place the item
    /// at a specific column, row, or named area, and to control its inline alignment.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     Text("Spanning header")
    /// }
    /// .gridPlacement(column: .range(1, -1), row: .line(1))
    ///
    /// Div {
    ///     Text("Named area")
    /// }
    /// .gridPlacement(area: "sidebar", justifySelf: .start)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `grid-column`, `grid-row`, `grid-area`, and
    /// `justify-self` properties.
    ///
    /// - Parameters:
    ///   - column: The grid column placement. Defaults to `nil`.
    ///   - row: The grid row placement. Defaults to `nil`.
    ///   - area: The named grid area. Defaults to `nil`.
    ///   - justifySelf: The inline-axis alignment. Defaults to `nil`.
    /// - Returns: A modified node with the grid placement styles applied.
    public func gridPlacement(column: GridSpan? = nil, row: GridSpan? = nil, area: String? = nil, justifySelf: TextAlign? = nil) -> ModifiedNode<Self> {
        let mod = GridPlacementModifier(column: column, row: row, area: area, justifySelf: justifySelf)
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
