/// The position of a radial gradient's center.
///
/// ### CSS Mapping
///
/// Maps to the `at <position>` part of a CSS `radial-gradient()` function.
public enum GradientPosition: String, Sendable {
    /// The gradient is centered at the top edge.
    ///
    /// CSS equivalent: `at center top`.
    case top = "center top"

    /// The gradient is centered in the element.
    ///
    /// CSS equivalent: `at center center`.
    case center = "center center"

    /// The gradient is centered at the bottom edge.
    ///
    /// CSS equivalent: `at center bottom`.
    case bottom = "center bottom"
}

/// A radial gradient specification for background images.
///
/// Describes an elliptical radial gradient that fades from a semi-transparent
/// color at the center to fully transparent at the edges. Useful for subtle
/// ambient glow effects on hero sections.
///
/// ### Example
///
/// ```swift
/// Section { ... }
///     .backgroundGradient(.radial(
///         color: .accent,
///         opacity: 0.04,
///         width: 120,
///         height: 80,
///         at: .top
///     ))
/// ```
///
/// ### CSS Mapping
///
/// Maps to a CSS `background-image: radial-gradient(...)` declaration.
public struct RadialGradient: Sendable {
    /// The color token at the gradient center.
    public let color: ColorToken

    /// The opacity of the color at the center, from `0.0` (invisible) to `1.0` (fully opaque).
    public let opacity: Double

    /// The horizontal extent of the gradient ellipse as a percentage of the element width.
    public let width: Double

    /// The vertical extent of the gradient ellipse as a percentage of the element height.
    public let height: Double

    /// The position of the gradient center within the element.
    public let position: GradientPosition

    /// Creates a radial gradient specification.
    ///
    /// - Parameters:
    ///   - color: The design-token color at the gradient center.
    ///   - opacity: Opacity of the center color, from `0.0` to `1.0`.
    ///   - width: Horizontal extent as a percentage (e.g. `120` for 120%).
    ///   - height: Vertical extent as a percentage (e.g. `80` for 80%).
    ///   - position: Where to place the gradient center. Defaults to `.center`.
    public static func radial(
        color: ColorToken,
        opacity: Double,
        width: Double = 100,
        height: Double = 100,
        at position: GradientPosition = .center
    ) -> RadialGradient {
        RadialGradient(
            color: color,
            opacity: opacity,
            width: width,
            height: height,
            position: position
        )
    }
}

/// A modifier that applies a radial gradient as a background image.
///
/// `BackgroundGradientModifier` creates a subtle elliptical gradient overlay,
/// commonly used for ambient glow effects behind hero content.
///
/// ### Example
///
/// ```swift
/// HeroSection()
///     .backgroundGradient(.radial(
///         color: .accent,
///         opacity: 0.04,
///         width: 120,
///         height: 80,
///         at: .top
///     ))
/// ```
///
/// ### CSS Mapping
///
/// Maps to a CSS `background-image: radial-gradient(...)` declaration.
public struct BackgroundGradientModifier: ModifierValue {
    /// The radial gradient specification.
    public let gradient: RadialGradient

    /// Creates a background gradient modifier.
    ///
    /// - Parameter gradient: The radial gradient to apply.
    public init(_ gradient: RadialGradient) {
        self.gradient = gradient
    }
}

extension Node {
    /// Applies a radial gradient as a background image.
    ///
    /// The gradient fades from a semi-transparent color at the center to
    /// fully transparent at the edges. This is useful for subtle ambient
    /// glow effects on hero sections.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Section { ... }
    ///     .backgroundGradient(.radial(
    ///         color: .accent,
    ///         opacity: 0.04,
    ///         width: 120,
    ///         height: 80,
    ///         at: .top
    ///     ))
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to a CSS `background-image: radial-gradient(...)` declaration.
    ///
    /// - Parameter gradient: The radial gradient specification.
    /// - Returns: A `ModifiedNode` with the gradient modifier applied.
    public func backgroundGradient(_ gradient: RadialGradient) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [BackgroundGradientModifier(gradient)])
    }
}
