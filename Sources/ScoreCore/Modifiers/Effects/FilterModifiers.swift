/// A type-safe CSS filter function.
///
/// `Filter` represents individual CSS filter functions that can be composed
/// together to create complex visual effects. Use the static factory methods
/// to create filter values, then pass one or more to the `.filter()` modifier.
///
/// ### Example
///
/// ```swift
/// Image("photo")
///     .filter(.grayscale(1))
///
/// Image("logo")
///     .filter(.blur(4), .brightness(0.8))
/// ```
///
/// ### CSS Mapping
///
/// Each value maps to a CSS filter function within the `filter` property.
public enum Filter: Sendable {
    /// Applies a Gaussian blur to the element.
    ///
    /// - Parameter radius: The blur radius in pixels.
    case blur(Double)

    /// Adjusts the brightness of the element.
    ///
    /// - Parameter amount: A multiplier where `1.0` is unchanged, `0.0` is
    ///   completely black, and values above `1.0` increase brightness.
    case brightness(Double)

    /// Adjusts the contrast of the element.
    ///
    /// - Parameter amount: A multiplier where `1.0` is unchanged, `0.0` is
    ///   completely grey, and values above `1.0` increase contrast.
    case contrast(Double)

    /// Converts the element to greyscale.
    ///
    /// - Parameter amount: The proportion of conversion, from `0.0` (unchanged)
    ///   to `1.0` (fully greyscale).
    case grayscale(Double)

    /// Rotates the hue of the element.
    ///
    /// - Parameter degrees: The angle of hue rotation in degrees.
    case hueRotate(Double)

    /// Inverts the colours of the element.
    ///
    /// - Parameter amount: The proportion of inversion, from `0.0` (unchanged)
    ///   to `1.0` (fully inverted).
    case invert(Double)

    /// Adjusts the opacity of the element.
    ///
    /// - Parameter amount: A value from `0.0` (fully transparent) to `1.0`
    ///   (fully opaque).
    case opacity(Double)

    /// Adjusts the saturation of the element.
    ///
    /// - Parameter amount: A multiplier where `1.0` is unchanged, `0.0` is
    ///   fully desaturated, and values above `1.0` increase saturation.
    case saturate(Double)

    /// Applies a sepia tone to the element.
    ///
    /// - Parameter amount: The proportion of conversion, from `0.0` (unchanged)
    ///   to `1.0` (fully sepia).
    case sepia(Double)

    /// The CSS string representation of this filter function.
    public var cssValue: String {
        switch self {
        case .blur(let v): "blur(\(v)px)"
        case .brightness(let v): "brightness(\(v))"
        case .contrast(let v): "contrast(\(v))"
        case .grayscale(let v): "grayscale(\(v))"
        case .hueRotate(let v): "hue-rotate(\(v)deg)"
        case .invert(let v): "invert(\(v))"
        case .opacity(let v): "opacity(\(v))"
        case .saturate(let v): "saturate(\(v))"
        case .sepia(let v): "sepia(\(v))"
        }
    }
}

/// A modifier that applies one or more CSS filter effects to a node.
///
/// `FilterModifier` accepts type-safe `Filter` values, providing access to all
/// common CSS filter functions such as `blur()`, `brightness()`, `contrast()`,
/// `grayscale()`, `hue-rotate()`, `invert()`, `saturate()`, and `sepia()`.
///
/// ### Example
///
/// ```swift
/// Image("photo")
///     .filter(.grayscale(1))
///
/// Image("logo")
///     .filter(.blur(4), .brightness(0.8))
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `filter` property on the rendered element.
public struct FilterModifier: ModifierValue {
    /// The filter functions to apply, in order.
    public let filters: [Filter]

    /// Creates a filter modifier with the given filter functions.
    ///
    /// - Parameter filters: The CSS filter functions to apply.
    public init(_ filters: [Filter]) {
        self.filters = filters
    }
}

/// A modifier that applies one or more CSS backdrop filter effects to a node.
///
/// `BackdropFilterModifier` applies filter effects to the area behind a node,
/// creating frosted-glass and similar effects. The node itself must have some
/// degree of transparency for the backdrop filter to be visible.
///
/// ### Example
///
/// ```swift
/// Panel()
///     .backdropFilter(.blur(12), .brightness(0.9))
///     .opacity(0.85)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `backdrop-filter` (and `-webkit-backdrop-filter`) property
/// on the rendered element.
///
/// - Important: The element must have a non-opaque background for the backdrop
///   filter to be visible through it.
public struct BackdropFilterModifier: ModifierValue {
    /// The filter functions to apply to the backdrop, in order.
    public let filters: [Filter]

    /// Creates a backdrop filter modifier with the given filter functions.
    ///
    /// - Parameter filters: The CSS filter functions applied to the area behind this node.
    public init(_ filters: [Filter]) {
        self.filters = filters
    }
}

/// How a node's colours are composited with the layers below it.
///
/// `BlendMode` controls the CSS `mix-blend-mode` property, which determines
/// how a node's pixel colours combine with the colours of elements it overlaps.
///
/// ### CSS Mapping
///
/// Maps to the CSS `mix-blend-mode` property.
public enum BlendMode: String, Sendable {
    /// No blending; the element is drawn normally over the background.
    ///
    /// CSS equivalent: `mix-blend-mode: normal`.
    case normal

    /// Multiplies the element and background colours, producing a darker result.
    ///
    /// CSS equivalent: `mix-blend-mode: multiply`.
    case multiply

    /// Multiplies the inverse of the colours, producing a lighter result.
    ///
    /// CSS equivalent: `mix-blend-mode: screen`.
    case screen

    /// Combines multiply and screen based on background luminance.
    ///
    /// CSS equivalent: `mix-blend-mode: overlay`.
    case overlay

    /// Retains the darker of the element and background colours.
    ///
    /// CSS equivalent: `mix-blend-mode: darken`.
    case darken

    /// Retains the lighter of the element and background colours.
    ///
    /// CSS equivalent: `mix-blend-mode: lighten`.
    case lighten

    /// Brightens the background by dividing it by the inverse of the element colour.
    ///
    /// CSS equivalent: `mix-blend-mode: color-dodge`.
    case colorDodge = "color-dodge"

    /// Darkens the background by dividing the inverse of the background by the element colour.
    ///
    /// CSS equivalent: `mix-blend-mode: color-burn`.
    case colorBurn = "color-burn"

    /// Combines multiply and screen based on the element colour.
    ///
    /// CSS equivalent: `mix-blend-mode: hard-light`.
    case hardLight = "hard-light"

    /// A softer version of hard-light blending.
    ///
    /// CSS equivalent: `mix-blend-mode: soft-light`.
    case softLight = "soft-light"

    /// Subtracts the darker of the two colours from the lighter.
    ///
    /// CSS equivalent: `mix-blend-mode: difference`.
    case difference

    /// A lower-contrast version of difference.
    ///
    /// CSS equivalent: `mix-blend-mode: exclusion`.
    case exclusion

    /// Preserves the hue of the element while using the saturation and luminosity of the background.
    ///
    /// CSS equivalent: `mix-blend-mode: hue`.
    case hue

    /// Preserves the saturation of the element while using the hue and luminosity of the background.
    ///
    /// CSS equivalent: `mix-blend-mode: saturation`.
    case saturation

    /// Preserves the hue and saturation of the element while using the luminosity of the background.
    ///
    /// CSS equivalent: `mix-blend-mode: color`.
    case color

    /// Preserves the luminosity of the element while using the hue and saturation of the background.
    ///
    /// CSS equivalent: `mix-blend-mode: luminosity`.
    case luminosity
}

/// A modifier that controls how a node's colours are composited with the layers below it.
///
/// ### Example
///
/// ```swift
/// Image("texture")
///     .blendMode(.multiply)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `mix-blend-mode` property on the rendered element.
public struct BlendModeModifier: ModifierValue {
    /// The blend mode controlling how colours are composited.
    public let mode: BlendMode

    /// Creates a blend mode modifier.
    ///
    /// - Parameter mode: The `BlendMode` value describing how colours are composited.
    public init(_ mode: BlendMode) {
        self.mode = mode
    }
}

extension Node {
    /// Applies one or more CSS filter effects to this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("photo")
    ///     .filter(.grayscale(1))
    ///
    /// Image("avatar")
    ///     .filter(.blur(2), .opacity(0.7))
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `filter` property on the rendered element.
    ///
    /// - Parameter filters: The CSS filter functions to apply.
    /// - Returns: A `ModifiedNode` with the filter modifier applied.
    public func filter(_ filters: Filter...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [FilterModifier(filters)])
    }

    /// Applies one or more CSS backdrop filter effects to the area behind this node.
    ///
    /// The node should have some transparency for the effect to be visible.
    ///
    /// ### Example
    ///
    /// ```swift
    /// FloatingPanel()
    ///     .backdropFilter(.blur(16), .brightness(0.95))
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `backdrop-filter` property on the rendered element.
    ///
    /// - Parameter filters: The CSS filter functions applied to content behind this node.
    /// - Returns: A `ModifiedNode` with the backdrop filter modifier applied.
    public func backdropFilter(_ filters: Filter...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [BackdropFilterModifier(filters)])
    }

    /// Controls how this node's colours are composited with overlapping layers below it.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("texture")
    ///     .blendMode(.multiply)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `mix-blend-mode` property on the rendered element.
    ///
    /// - Parameter mode: The `BlendMode` value describing how colours are composited.
    /// - Returns: A `ModifiedNode` with the blend mode modifier applied.
    public func blendMode(_ mode: BlendMode) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [BlendModeModifier(mode)])
    }
}
