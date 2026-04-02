/// A modifier that sets the transparency level of a node.
///
/// `OpacityModifier` adjusts how opaque or translucent a node appears by
/// setting its `opacity` CSS property. A value of `1.0` is fully opaque and
/// `0.0` is fully transparent. The modifier affects the entire node and all
/// of its descendents.
///
/// ### Example
///
/// ```swift
/// Image("hero")
///     .opacity(0.75)
///
/// DisabledButton()
///     .opacity(0.4)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `opacity` property on the rendered element.
public struct OpacityModifier: ModifierValue {
    /// The opacity level, where `0.0` is fully transparent and `1.0` is fully opaque.
    public let value: Double

    /// Creates an opacity modifier.
    ///
    /// - Parameter value: A `Double` in the range `0.0` (transparent) to `1.0` (opaque).
    public init(_ value: Double) {
        self.value = value
    }
}

/// A modifier that applies a drop shadow to a node.
///
/// `ShadowModifier` renders a box shadow beneath (or around) a node using
/// configurable offset, blur, spread, and color values.
///
/// ### Example
///
/// ```swift
/// Card()
///     .shadow(x: 0, y: 4, blur: 12, spread: 0, color: .shadow)
///
/// Modal()
///     .shadow(x: 0, y: 8, blur: 24, spread: -4, color: .shadow)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `box-shadow` property on the rendered element,
/// rendered as `box-shadow: {x}px {y}px {blur}px {spread}px {color}`.
public struct ShadowModifier: ModifierValue {
    /// The horizontal offset of the shadow in points. Positive values move the shadow right.
    public let x: Double

    /// The vertical offset of the shadow in points. Positive values move the shadow downward.
    public let y: Double

    /// The blur radius of the shadow in points. Larger values produce a softer, more diffuse shadow.
    public let blur: Double

    /// The spread radius of the shadow in points. Positive values expand the shadow; negative values contract it.
    public let spread: Double

    /// The design-token color of the shadow.
    public let color: ColorToken

    /// Creates a shadow modifier.
    ///
    /// - Parameters:
    ///   - x: Horizontal offset in points.
    ///   - y: Vertical offset in points.
    ///   - blur: Blur radius in points.
    ///   - spread: Spread radius in points. Defaults to `0`.
    ///   - color: The shadow color as a design token.
    public init(x: Double, y: Double, blur: Double, spread: Double = 0, color: ColorToken) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        self.color = color
    }
}

extension Node {
    /// Sets the transparency level of this node and all its descendants.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("hero")
    ///     .opacity(0.8)
    ///
    /// DisabledButton()
    ///     .opacity(0.4)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `opacity` property on the rendered element.
    ///
    /// - Parameter value: A value between `0.0` (fully transparent) and `1.0` (fully opaque).
    /// - Returns: A `ModifiedNode` with the opacity modifier applied.
    public func opacity(_ value: Double) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [OpacityModifier(value)])
    }

    /// Applies a drop shadow to this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .shadow(x: 0, y: 4, blur: 16, color: .shadow)
    ///
    /// Modal()
    ///     .shadow(x: 0, y: 8, blur: 32, spread: -4, color: .shadow)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `box-shadow` property on the rendered element.
    ///
    /// - Parameters:
    ///   - x: Horizontal shadow offset in points.
    ///   - y: Vertical shadow offset in points.
    ///   - blur: Blur radius in points.
    ///   - spread: Spread radius in points. Defaults to `0`.
    ///   - color: The shadow color as a design token.
    /// - Returns: A `ModifiedNode` with the shadow modifier applied.
    public func shadow(x: Double, y: Double, blur: Double, spread: Double = 0, color: ColorToken) -> ModifiedNode<Self> {
        let mod = ShadowModifier(x: x, y: y, blur: blur, spread: spread, color: color)
        return ModifiedNode(content: self, modifiers: [mod])
    }

}
