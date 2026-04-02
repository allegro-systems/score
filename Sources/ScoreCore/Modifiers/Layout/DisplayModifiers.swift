/// Specifies how an element is rendered in the document flow.
///
/// `DisplayMode` controls the outer display type of an element, determining
/// whether it participates in block or inline formatting context, or is
/// removed from the layout entirely.
///
/// ### CSS Mapping
///
/// Maps to the CSS `display` property.
public enum DisplayMode: String, Sendable {

    /// The element generates a block-level box.
    ///
    /// Block elements stack vertically and take up the full width available.
    /// Equivalent to CSS `block`.
    case block

    /// The element generates one or more inline boxes.
    ///
    /// Inline elements flow with surrounding text and do not break onto a new line.
    /// Equivalent to CSS `inline`.
    case inline

    /// The element generates a block box that flows inline with surrounding content.
    ///
    /// Combines block-level sizing (width, height, padding) with inline flow behaviour.
    /// Equivalent to CSS `inline-block`.
    case inlineBlock = "inline-block"

    /// The element generates a flex container that flows inline.
    ///
    /// Equivalent to CSS `inline-flex`.
    case inlineFlex = "inline-flex"

    /// The element itself is not rendered, but its children are.
    ///
    /// Useful for wrapper elements that should not introduce a box of their own.
    /// Equivalent to CSS `contents`.
    case contents

    /// The element is not rendered and takes up no space in the layout.
    ///
    /// Equivalent to CSS `none`. To visually hide while preserving layout space,
    /// use `visibility: hidden` instead.
    case none
}

/// Specifies how content that overflows an element's box is handled.
///
/// `OverflowMode` controls whether overflowing content is visible, clipped,
/// scrollable, or automatically managed by the browser.
///
/// ### CSS Mapping
///
/// Maps to the CSS `overflow`, `overflow-x`, and `overflow-y` properties.
public enum OverflowMode: String, Sendable {

    /// Overflowing content is rendered outside the element's bounds.
    ///
    /// This is the default browser behaviour. Equivalent to CSS `visible`.
    case visible

    /// Overflowing content is clipped and not accessible via scrolling.
    ///
    /// Equivalent to CSS `hidden`.
    case hidden

    /// Overflowing content is clipped without creating a scrollable container.
    ///
    /// Unlike `hidden`, `clip` also prevents programmatic scrolling.
    /// Equivalent to CSS `clip`.
    case clip

    /// Overflowing content is clipped, and a scrollbar is always shown.
    ///
    /// Equivalent to CSS `scroll`.
    case scroll

    /// The browser decides whether to show scrollbars based on content overflow.
    ///
    /// Scrollbars are shown only when content actually overflows.
    /// Equivalent to CSS `auto`.
    case auto
}

/// A modifier that sets the display type of an element.
///
/// `DisplayModifier` applies the CSS `display` property, controlling how the
/// node participates in the document's layout flow.
///
/// ### Example
///
/// ```swift
/// Span {
///     Text("Block-level span")
/// }
/// .display(.block)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `display` property on the rendered element.
public struct DisplayModifier: ModifierValue {

    /// The display mode to apply to the element.
    public let mode: DisplayMode

    /// Creates a display modifier.
    ///
    /// - Parameter mode: The display mode to apply.
    public init(_ mode: DisplayMode) {
        self.mode = mode
    }
}

/// A modifier that controls how content overflowing the element's box is handled.
///
/// `OverflowModifier` allows independent control over horizontal and vertical overflow,
/// mapping directly to CSS `overflow-x` and `overflow-y`.
///
/// ### Example
///
/// ```swift
/// Div {
///     LongContent()
/// }
/// .overflow(x: .hidden, y: .scroll)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `overflow-x` and `overflow-y` properties. When both axes share
/// the same value, this is equivalent to the shorthand `overflow` property.
public struct OverflowModifier: ModifierValue {

    /// The overflow mode to apply along the horizontal axis.
    ///
    /// When `nil`, the horizontal overflow is not explicitly set.
    public let x: OverflowMode?

    /// The overflow mode to apply along the vertical axis.
    ///
    /// When `nil`, the vertical overflow is not explicitly set.
    public let y: OverflowMode?

    /// Creates an overflow modifier with independent axis control.
    ///
    /// - Parameters:
    ///   - x: The overflow mode for the horizontal axis. Pass `nil` to leave unset.
    ///   - y: The overflow mode for the vertical axis. Pass `nil` to leave unset.
    public init(x: OverflowMode? = nil, y: OverflowMode? = nil) {
        self.x = x
        self.y = y
    }
}

extension Node {

    /// Sets the display type of the element.
    ///
    /// Use this modifier to control how the element participates in the document flow.
    /// For flex and grid containers, use the dedicated `.flex(...)` and `.grid(...)`
    /// modifiers instead.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Span {
    ///     Text("Now block-level")
    /// }
    /// .display(.block)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `display` property.
    ///
    /// - Parameter mode: The display mode to apply.
    /// - Returns: A modified node with the display style applied.
    public func display(_ mode: DisplayMode) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [DisplayModifier(mode)])
    }

    /// Sets the overflow behaviour uniformly on both axes.
    ///
    /// Applies the same overflow mode to both the horizontal and vertical axes.
    /// Use the two-parameter overload for independent axis control.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     LongContent()
    /// }
    /// .overflow(.hidden)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `overflow` shorthand property (sets both `overflow-x` and `overflow-y`).
    ///
    /// - Parameter mode: The overflow mode to apply to both axes.
    /// - Returns: A modified node with the overflow style applied.
    public func overflow(_ mode: OverflowMode) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [OverflowModifier(x: mode, y: mode)])
    }

    /// Sets the overflow behaviour independently for the horizontal and vertical axes.
    ///
    /// Pass a value for each axis you want to control. Omitting an axis leaves it
    /// at its default or previously inherited value.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     LongContent()
    /// }
    /// .overflow(x: .hidden, y: .auto)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `overflow-x` and `overflow-y` properties.
    ///
    /// - Parameters:
    ///   - x: The overflow mode for the horizontal axis. Defaults to `nil`.
    ///   - y: The overflow mode for the vertical axis. Defaults to `nil`.
    /// - Returns: A modified node with the per-axis overflow styles applied.
    public func overflow(x: OverflowMode? = nil, y: OverflowMode? = nil) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [OverflowModifier(x: x, y: y)])
    }
}
