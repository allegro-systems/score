/// The axis along which flex items are laid out.
///
/// `FlexDirection` controls whether the main axis of the flex container runs
/// horizontally or vertically, determining the direction items are placed.
///
/// ### CSS Mapping
///
/// Maps to the CSS `flex-direction` property.
public enum FlexDirection: String, Sendable {

    /// Items are arranged horizontally from leading to trailing.
    ///
    /// Equivalent to CSS `row`.
    case row

    /// Items are arranged vertically from top to bottom.
    ///
    /// Equivalent to CSS `column`.
    case column
}

/// The cross-axis alignment of flex items or grid items within their container.
///
/// `FlexAlign` is used for both the `align-items` property on flex/grid containers
/// and the `align-self` override on individual items.
///
/// ### CSS Mapping
///
/// Maps to the CSS `align-items` and `align-self` properties.
public enum FlexAlign: String, Sendable {

    /// Items are aligned to the start of the cross axis.
    ///
    /// Equivalent to CSS `flex-start` (or `start` in grid contexts).
    case start

    /// Items are centered along the cross axis.
    ///
    /// Equivalent to CSS `center`.
    case center

    /// Items are aligned to the end of the cross axis.
    ///
    /// Equivalent to CSS `flex-end` (or `end` in grid contexts).
    case end

    /// Items are stretched to fill the cross-axis size of the container.
    ///
    /// Equivalent to CSS `stretch`.
    case stretch

    /// Items are aligned to their text baselines.
    ///
    /// Equivalent to CSS `baseline`.
    case baseline
}

/// The main-axis distribution of flex items within their container.
///
/// `FlexJustify` controls how extra space is allocated along the main axis
/// after items have been sized.
///
/// ### CSS Mapping
///
/// Maps to the CSS `justify-content` property.
public enum FlexJustify: String, Sendable {

    /// Items are packed toward the start of the main axis.
    ///
    /// Equivalent to CSS `flex-start` (or `start`).
    case start

    /// Items are centered along the main axis.
    ///
    /// Equivalent to CSS `center`.
    case center

    /// Items are packed toward the end of the main axis.
    ///
    /// Equivalent to CSS `flex-end` (or `end`).
    case end

    /// Items are evenly distributed with the first item at the start and the last at the end.
    ///
    /// Equivalent to CSS `space-between`.
    case spaceBetween = "space-between"

    /// Items are evenly distributed with equal space before the first and after the last item.
    ///
    /// Equivalent to CSS `space-around`.
    case spaceAround = "space-around"

    /// Items are evenly distributed with equal space between all items and container edges.
    ///
    /// Equivalent to CSS `space-evenly`.
    case spaceEvenly = "space-evenly"
}

/// The placement algorithm used for auto-placed grid items.
///
/// `GridAutoFlow` controls how the browser fills in grid cells for items that
/// are not explicitly placed, and whether a dense packing algorithm is used.
///
/// ### CSS Mapping
///
/// Maps to the CSS `grid-auto-flow` property.
public enum GridAutoFlow: String, Sendable {

    /// Auto-placed items fill each row before moving to the next.
    ///
    /// Equivalent to CSS `row`.
    case row

    /// Auto-placed items fill each column before moving to the next.
    ///
    /// Equivalent to CSS `column`.
    case column

    /// The dense packing algorithm fills in holes earlier in the grid.
    ///
    /// Equivalent to CSS `dense`.
    case dense

    /// Auto-placed items fill each row using the dense packing algorithm.
    ///
    /// Equivalent to CSS `row dense`.
    case rowDense = "row dense"

    /// Auto-placed items fill each column using the dense packing algorithm.
    ///
    /// Equivalent to CSS `column dense`.
    case columnDense = "column dense"
}

/// A modifier that turns an element into a flex container.
///
/// `FlexModifier` applies CSS Flexbox layout to a node, controlling the main axis
/// direction, the gap between items, cross-axis alignment, main-axis justification,
/// and whether items are allowed to wrap onto multiple lines.
///
/// ### Example
///
/// ```swift
/// Div {
///     Text("Item 1")
///     Text("Item 2")
///     Text("Item 3")
/// }
/// .flex(.row, gap: 16, align: .center, justify: .spaceBetween, wrap: true)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `display: flex`, `flex-direction`, `gap`, `align-items`,
/// `justify-content`, and `flex-wrap` properties on the rendered element.
public struct FlexModifier: ModifierValue {

    /// The direction of the main axis.
    ///
    /// Equivalent to CSS `flex-direction`.
    public let direction: FlexDirection

    /// The space between flex items in points.
    ///
    /// When `nil`, the CSS `gap` property is not set.
    public let gap: Double?

    /// The cross-axis alignment of all items in the container.
    ///
    /// When `nil`, the CSS `align-items` property is not set.
    public let align: FlexAlign?

    /// The main-axis distribution of items after they are sized.
    ///
    /// When `nil`, the CSS `justify-content` property is not set.
    public let justify: FlexJustify?

    /// Whether flex items can wrap onto multiple lines.
    ///
    /// When `true`, maps to CSS `flex-wrap: wrap`. When `false`, maps to `flex-wrap: nowrap`.
    public let wraps: Bool

    /// Creates a flex modifier.
    ///
    /// - Parameters:
    ///   - direction: The main axis direction for the flex container.
    ///   - gap: The gap between items in points. Defaults to `nil`.
    ///   - align: The cross-axis alignment for all items. Defaults to `nil`.
    ///   - justify: The main-axis distribution of items. Defaults to `nil`.
    ///   - wraps: Whether items wrap onto multiple lines. Defaults to `false`.
    public init(
        _ direction: FlexDirection,
        gap: Double? = nil,
        align: FlexAlign? = nil,
        justify: FlexJustify? = nil,
        wraps: Bool = false
    ) {
        self.direction = direction
        self.gap = gap
        self.align = align
        self.justify = justify
        self.wraps = wraps
    }
}

/// A modifier that turns an element into a grid container.
///
/// `GridModifier` applies CSS Grid layout to a node, controlling the number of
/// columns and rows, the gap between tracks, and the auto-placement algorithm.
///
/// ### Example
///
/// ```swift
/// Div {
///     ForEach(items) { item in
///         Card(item)
///     }
/// }
/// .grid(columns: 3, gap: 24, autoFlow: .rowDense)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `display: grid`, `grid-template-columns`, `grid-template-rows`,
/// `gap`, and `grid-auto-flow` properties on the rendered element.
public struct GridModifier: ModifierValue {

    /// The number of equal-width columns in the grid.
    ///
    /// Rendered as `grid-template-columns: repeat(<columns>, 1fr)`.
    public let columns: Int

    /// The number of explicitly defined rows in the grid.
    ///
    /// When `nil`, the CSS `grid-template-rows` property is not set and rows are
    /// created implicitly as needed.
    public let rows: Int?

    /// The space between grid tracks (rows and columns) in points.
    ///
    /// When `nil`, the CSS `gap` property is not set.
    public let gap: Double?

    /// The algorithm used to place auto-positioned grid items.
    ///
    /// When `nil`, the CSS `grid-auto-flow` property is not set.
    public let autoFlow: GridAutoFlow?

    /// Creates a grid modifier.
    ///
    /// - Parameters:
    ///   - columns: The number of equal-width columns.
    ///   - rows: The number of explicitly defined rows. Defaults to `nil`.
    ///   - gap: The gap between tracks in points. Defaults to `nil`.
    ///   - autoFlow: The auto-placement algorithm. Defaults to `nil`.
    public init(columns: Int, rows: Int? = nil, gap: Double? = nil, autoFlow: GridAutoFlow? = nil) {
        self.columns = columns
        self.rows = rows
        self.gap = gap
        self.autoFlow = autoFlow
    }
}

/// A modifier that hides an element from the layout entirely.
///
/// `HiddenModifier` removes the element from the rendered output by setting
/// `display: none`, which means it occupies no space and is not accessible
/// to assistive technologies.
///
/// ### Example
///
/// ```swift
/// Div {
///     Text("Hidden content")
/// }
/// .hidden()
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `display: none` property on the rendered element.
///
/// - Important: Use `.display(.none)` directly for an equivalent one-liner.
///   For visually hiding while preserving layout, apply `visibility: hidden` instead.
public struct HiddenModifier: ModifierValue {

    /// Creates a hidden modifier.
    public init() {}
}

extension Node {

    /// Turns the element into a flex container with the specified layout options.
    ///
    /// Apply this modifier to a parent node to arrange its children using CSS Flexbox.
    /// Combine with `.flexItem(...)` on individual children for full control over
    /// item sizing and alignment.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     Text("Left")
    ///     Spacer()
    ///     Text("Right")
    /// }
    /// .flex(.row, gap: 8, align: .center, justify: .spaceBetween)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `display: flex`, `flex-direction`, `gap`, `align-items`,
    /// `justify-content`, and `flex-wrap` properties.
    ///
    /// - Parameters:
    ///   - direction: The main axis direction (`.row` or `.column`).
    ///   - gap: The gap between items in points. Defaults to `nil`.
    ///   - align: The cross-axis alignment for all items. Defaults to `nil`.
    ///   - justify: The main-axis distribution of items. Defaults to `nil`.
    ///   - wraps: Whether items wrap onto multiple lines. Defaults to `false`.
    /// - Returns: A modified node configured as a flex container.
    public func flex(
        _ direction: FlexDirection,
        gap: Double? = nil,
        align: FlexAlign? = nil,
        justify: FlexJustify? = nil,
        wraps: Bool = false
    ) -> ModifiedNode<Self> {
        let mod = FlexModifier(direction, gap: gap, align: align, justify: justify, wraps: wraps)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Turns the element into a grid container with the specified number of columns.
    ///
    /// Apply this modifier to a parent node to arrange its children using CSS Grid.
    /// Combine with `.gridPlacement(...)` on individual children to place them
    /// at specific tracks or named areas.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     ForEach(products) { product in
    ///         ProductCard(product)
    ///     }
    /// }
    /// .grid(columns: 4, gap: 16)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `display: grid`, `grid-template-columns`, `grid-template-rows`,
    /// `gap`, and `grid-auto-flow` properties.
    ///
    /// - Parameters:
    ///   - columns: The number of equal-width columns.
    ///   - rows: The number of explicitly defined rows. Defaults to `nil`.
    ///   - gap: The gap between tracks in points. Defaults to `nil`.
    ///   - autoFlow: The auto-placement algorithm. Defaults to `nil`.
    /// - Returns: A modified node configured as a grid container.
    public func grid(columns: Int, rows: Int? = nil, gap: Double? = nil, autoFlow: GridAutoFlow? = nil) -> ModifiedNode<Self> {
        let mod = GridModifier(columns: columns, rows: rows, gap: gap, autoFlow: autoFlow)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Hides the element by removing it from the layout entirely.
    ///
    /// The element is not rendered and occupies no space. Use this when you want
    /// to conditionally exclude content from the page without altering the surrounding
    /// layout structure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     Text("Secret content")
    /// }
    /// .hidden()
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `display: none` property.
    ///
    /// - Returns: A modified node that is hidden from the rendered output.
    public func hidden() -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [HiddenModifier()])
    }
}
