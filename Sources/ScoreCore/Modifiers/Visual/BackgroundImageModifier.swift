/// How a background image is tiled when it is smaller than its container.
///
/// `BackgroundRepeat` controls whether and in which directions a background image
/// is repeated to fill the element's background area.
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-repeat` property.
public enum BackgroundRepeat: String, Sendable {
    /// The image is not repeated; it appears only once.
    ///
    /// CSS equivalent: `background-repeat: no-repeat`.
    case noRepeat = "no-repeat"

    /// The image is repeated only along the horizontal axis.
    ///
    /// CSS equivalent: `background-repeat: repeat-x`.
    case repeatX = "repeat-x"

    /// The image is repeated only along the vertical axis.
    ///
    /// CSS equivalent: `background-repeat: repeat-y`.
    case repeatY = "repeat-y"

    /// The image is repeated along both axes to fill the entire background.
    ///
    /// CSS equivalent: `background-repeat: repeat`.
    case `repeat`

    /// The image is repeated and spaced evenly to avoid clipping,
    /// with extra space distributed between copies.
    ///
    /// CSS equivalent: `background-repeat: space`.
    case space

    /// The image is repeated and scaled so that it fills the axis without clipping.
    ///
    /// CSS equivalent: `background-repeat: round`.
    case round
}

/// A modifier that applies an image to the background of a node.
///
/// `BackgroundImageModifier` provides control over the image source, sizing,
/// positioning, repeat mode, and clipping box for element backgrounds.
/// All properties are optional; you can provide only the values you need.
///
/// ### Example
///
/// ```swift
/// HeroSection()
///     .backgroundImage(
///         "url('/images/hero.jpg')",
///         size: "cover",
///         position: "center",
///         repeat: .noRepeat
///     )
///
/// Pattern()
///     .backgroundImage("url('/images/tile.png')", repeat: .repeat)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-image`, `background-size`, `background-position`,
/// `background-repeat`, and `background-clip` properties on the rendered element.
public struct BackgroundImageModifier: ModifierValue {
    /// The CSS image value, such as a `url(...)` string or a gradient function.
    ///
    /// When `nil`, no image is applied.
    public let image: String?

    /// The CSS `background-size` value, such as `"cover"`, `"contain"`, or `"100px 200px"`.
    ///
    /// When `nil`, the browser's default size (`auto`) is used.
    public let size: String?

    /// The CSS `background-position` value, such as `"center"` or `"top right"`.
    ///
    /// When `nil`, the browser's default position (`0% 0%`) is used.
    public let position: String?

    /// The repeat mode applied to the background image.
    ///
    /// When `nil`, the browser's default repeat behavior is used.
    public let repeatMode: BackgroundRepeat?

    /// The CSS `background-clip` value, such as `"border-box"` or `"text"`.
    ///
    /// When `nil`, the browser's default clipping box (`border-box`) is used.
    public let clip: String?

    /// Creates a background image modifier.
    ///
    /// - Parameters:
    ///   - image: A CSS image value such as `"url('/img/bg.png')"` or a gradient string.
    ///   - size: Optional CSS `background-size` value.
    ///   - position: Optional CSS `background-position` value.
    ///   - repeatMode: Optional `BackgroundRepeat` mode.
    ///   - clip: Optional CSS `background-clip` value.
    public init(image: String? = nil, size: String? = nil, position: String? = nil, repeatMode: BackgroundRepeat? = nil, clip: String? = nil) {
        self.image = image
        self.size = size
        self.position = position
        self.repeatMode = repeatMode
        self.clip = clip
    }
}

extension Node {
    /// Applies a background image to this node.
    ///
    /// Use this modifier to set a CSS image or gradient as the background of a node.
    /// Combine the size, position, repeat, and clip parameters to achieve the
    /// exact background layout you need.
    ///
    /// ### Example
    ///
    /// ```swift
    /// HeroSection()
    ///     .backgroundImage(
    ///         "url('/images/hero.jpg')",
    ///         size: "cover",
    ///         position: "center",
    ///         repeat: .noRepeat
    ///     )
    ///
    /// GradientBox()
    ///     .backgroundImage("linear-gradient(to right, #f00, #00f)", size: "100% 100%")
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `background-image`, `background-size`, `background-position`,
    /// `background-repeat`, and `background-clip` properties on the rendered element.
    ///
    /// - Parameters:
    ///   - image: A CSS image value such as `"url('/img/bg.png')"` or a gradient function.
    ///   - size: Optional CSS `background-size` value. Defaults to `nil`.
    ///   - position: Optional CSS `background-position` value. Defaults to `nil`.
    ///   - repeatMode: Optional `BackgroundRepeat` mode controlling tiling. Defaults to `nil`.
    ///   - clip: Optional CSS `background-clip` value. Defaults to `nil`.
    /// - Returns: A `ModifiedNode` with the background image modifier applied.
    public func backgroundImage(_ image: String, size: String? = nil, position: String? = nil, repeat repeatMode: BackgroundRepeat? = nil, clip: String? = nil) -> ModifiedNode<
        Self
    > {
        let mod = BackgroundImageModifier(image: image, size: size, position: position, repeatMode: repeatMode, clip: clip)
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
