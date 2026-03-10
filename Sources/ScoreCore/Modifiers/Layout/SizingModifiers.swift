/// A modifier that constrains the width and height of an element.
///
/// `SizeModifier` applies any combination of explicit, minimum, and maximum
/// width and height values to a node. Only the properties that are explicitly
/// set are emitted in the rendered CSS output; omitted values are left at their
/// inherited or default browser values.
///
/// Values may be specified as pixel literals or as percentages using
/// ``Length/percent(_:)``.
///
/// ### Example
///
/// ```swift
/// Div {
///     Text("Constrained box")
/// }
/// .size(width: 320, minHeight: 120, maxHeight: 480)
///
/// Article {
///     Text("Fills parent height")
/// }
/// .size(height: .percent(100))
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `width`, `height`, `min-width`, `min-height`, `max-width`,
/// and `max-height` properties on the rendered element.
public struct SizeModifier: ModifierValue {

    /// The explicit width of the element.
    ///
    /// When `nil`, the CSS `width` property is not set.
    public let width: Length?

    /// The explicit height of the element.
    ///
    /// When `nil`, the CSS `height` property is not set.
    public let height: Length?

    /// The minimum width of the element.
    ///
    /// When `nil`, the CSS `min-width` property is not set.
    public let minWidth: Length?

    /// The minimum height of the element.
    ///
    /// When `nil`, the CSS `min-height` property is not set.
    public let minHeight: Length?

    /// The maximum width of the element.
    ///
    /// When `nil`, the CSS `max-width` property is not set.
    public let maxWidth: Length?

    /// The maximum height of the element.
    ///
    /// When `nil`, the CSS `max-height` property is not set.
    public let maxHeight: Length?

    /// Creates a size modifier.
    ///
    /// All parameters are optional. Omit any parameter to leave its corresponding
    /// CSS property unset. Bare numeric literals are interpreted as pixel values.
    ///
    /// - Parameters:
    ///   - width: The explicit width. Defaults to `nil`.
    ///   - height: The explicit height. Defaults to `nil`.
    ///   - minWidth: The minimum width. Defaults to `nil`.
    ///   - minHeight: The minimum height. Defaults to `nil`.
    ///   - maxWidth: The maximum width. Defaults to `nil`.
    ///   - maxHeight: The maximum height. Defaults to `nil`.
    public init(
        width: Length? = nil,
        height: Length? = nil,
        minWidth: Length? = nil,
        minHeight: Length? = nil,
        maxWidth: Length? = nil,
        maxHeight: Length? = nil
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
}

/// A modifier that enforces a fixed aspect ratio on an element.
///
/// `AspectRatioModifier` applies the CSS `aspect-ratio` property, causing the
/// browser to maintain the given width-to-height ratio when only one dimension
/// is explicitly sized. This is especially useful for images, videos, and
/// other embedded media.
///
/// ### Example
///
/// ```swift
/// Image("hero")
///     .aspectRatio(16.0 / 9.0)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `aspect-ratio` property on the rendered element.
public struct AspectRatioModifier: ModifierValue {

    /// The width-to-height ratio to maintain.
    ///
    /// For example, pass `16.0 / 9.0` for a widescreen ratio, or `1.0` for a square.
    /// Equivalent to CSS `aspect-ratio: <ratio>`.
    public let ratio: Double

    /// Creates an aspect ratio modifier.
    ///
    /// - Parameter ratio: The width-to-height ratio to enforce.
    public init(_ ratio: Double) {
        self.ratio = ratio
    }
}

extension Node {

    /// Sets explicit, minimum, and maximum dimensions for the element.
    ///
    /// Use this modifier when you need to control one or more of the
    /// six sizing CSS properties.
    ///
    /// Bare numeric literals are interpreted as pixel values. Use
    /// ``Length/percent(_:)`` for relative sizing.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div {
    ///     Text("Fluid column")
    /// }
    /// .size(minWidth: 200, maxWidth: 600)
    ///
    /// Article {
    ///     Text("Fills parent height")
    /// }
    /// .size(height: .percent(100))
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `width`, `height`, `min-width`, `min-height`, `max-width`,
    /// and `max-height` properties.
    ///
    /// - Parameters:
    ///   - width: The explicit width. Defaults to `nil`.
    ///   - height: The explicit height. Defaults to `nil`.
    ///   - minWidth: The minimum width. Defaults to `nil`.
    ///   - minHeight: The minimum height. Defaults to `nil`.
    ///   - maxWidth: The maximum width. Defaults to `nil`.
    ///   - maxHeight: The maximum height. Defaults to `nil`.
    /// - Returns: A modified node with the sizing styles applied.
    public func size(
        width: Length? = nil,
        height: Length? = nil,
        minWidth: Length? = nil,
        minHeight: Length? = nil,
        maxWidth: Length? = nil,
        maxHeight: Length? = nil
    ) -> ModifiedNode<Self> {
        let mod = SizeModifier(
            width: width,
            height: height,
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Enforces a fixed width-to-height aspect ratio on the element.
    ///
    /// The browser will automatically calculate the missing dimension to maintain
    /// the ratio when only `width` or only `height` is specified. Particularly
    /// useful for responsive images, video embeds, and square thumbnails.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("thumbnail")
    ///     .size(width: 320)
    ///     .aspectRatio(16.0 / 9.0)
    ///
    /// Div {
    ///     Text("Square tile")
    /// }
    /// .aspectRatio(1.0)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `aspect-ratio` property.
    ///
    /// - Parameter ratio: The width-to-height ratio to enforce.
    /// - Returns: A modified node with the aspect-ratio style applied.
    public func aspectRatio(_ ratio: Double) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [AspectRatioModifier(ratio)])
    }
}
