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

/// How a background image is sized within its container.
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-size` property.
public enum BackgroundSize: String, Sendable {
    /// The image is scaled to cover the entire container, preserving aspect ratio.
    /// Parts of the image may be clipped.
    ///
    /// CSS equivalent: `background-size: cover`.
    case cover

    /// The image is scaled to fit entirely within the container, preserving aspect ratio.
    /// The container may have empty space.
    ///
    /// CSS equivalent: `background-size: contain`.
    case contain

    /// The image is rendered at its intrinsic size.
    ///
    /// CSS equivalent: `background-size: auto`.
    case auto
}

/// The alignment of a background image within its container.
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-position` property.
public enum BackgroundPosition: String, Sendable {
    /// Centres the image in both axes.
    ///
    /// CSS equivalent: `background-position: center`.
    case center

    /// Aligns the image to the top edge.
    ///
    /// CSS equivalent: `background-position: top`.
    case top

    /// Aligns the image to the bottom edge.
    ///
    /// CSS equivalent: `background-position: bottom`.
    case bottom

    /// Aligns the image to the left edge.
    ///
    /// CSS equivalent: `background-position: left`.
    case left

    /// Aligns the image to the right edge.
    ///
    /// CSS equivalent: `background-position: right`.
    case right

    /// Aligns the image to the top-left corner.
    ///
    /// CSS equivalent: `background-position: top left`.
    case topLeft = "top left"

    /// Aligns the image to the top-right corner.
    ///
    /// CSS equivalent: `background-position: top right`.
    case topRight = "top right"

    /// Aligns the image to the bottom-left corner.
    ///
    /// CSS equivalent: `background-position: bottom left`.
    case bottomLeft = "bottom left"

    /// Aligns the image to the bottom-right corner.
    ///
    /// CSS equivalent: `background-position: bottom right`.
    case bottomRight = "bottom right"
}

/// The painting area of a background image.
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-clip` property.
public enum BackgroundClip: String, Sendable {
    /// The background extends to the outer edge of the border.
    ///
    /// CSS equivalent: `background-clip: border-box`.
    case borderBox = "border-box"

    /// The background extends to the outer edge of the padding.
    ///
    /// CSS equivalent: `background-clip: padding-box`.
    case paddingBox = "padding-box"

    /// The background extends to the edge of the content box.
    ///
    /// CSS equivalent: `background-clip: content-box`.
    case contentBox = "content-box"

    /// The background is clipped to the foreground text.
    ///
    /// CSS equivalent: `background-clip: text`.
    case text
}

/// A modifier that applies a background image to a node.
///
/// `BackgroundImageModifier` provides control over the image source, sizing,
/// positioning, repeat mode, and clipping box for element backgrounds.
///
/// ### Example
///
/// ```swift
/// HeroSection()
///     .backgroundImage(
///         url: "/images/hero.jpg",
///         size: .cover,
///         position: .center,
///         repeat: .noRepeat
///     )
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `background-image`, `background-size`, `background-position`,
/// `background-repeat`, and `background-clip` properties on the rendered element.
public struct BackgroundImageModifier: ModifierValue {
    /// The URL path of the background image.
    ///
    /// The framework wraps this in a CSS `url()` function automatically.
    public let url: String

    /// How the background image is sized.
    ///
    /// When `nil`, the browser's default size (`auto`) is used.
    public let size: BackgroundSize?

    /// The alignment of the background image.
    ///
    /// When `nil`, the browser's default position (`0% 0%`) is used.
    public let position: BackgroundPosition?

    /// The repeat mode applied to the background image.
    ///
    /// When `nil`, the browser's default repeat behavior is used.
    public let repeatMode: BackgroundRepeat?

    /// The painting area of the background image.
    ///
    /// When `nil`, the browser's default clipping box (`border-box`) is used.
    public let clip: BackgroundClip?

    /// Creates a background image modifier.
    ///
    /// - Parameters:
    ///   - url: The URL path of the background image.
    ///   - size: Optional background sizing mode.
    ///   - position: Optional background alignment.
    ///   - repeatMode: Optional repeat mode.
    ///   - clip: Optional painting area.
    public init(url: String, size: BackgroundSize? = nil, position: BackgroundPosition? = nil, repeatMode: BackgroundRepeat? = nil, clip: BackgroundClip? = nil) {
        self.url = url
        self.size = size
        self.position = position
        self.repeatMode = repeatMode
        self.clip = clip
    }
}

extension Node {
    /// Applies a background image to this node.
    ///
    /// The framework wraps the URL path in a CSS `url()` function automatically.
    ///
    /// ### Example
    ///
    /// ```swift
    /// HeroSection()
    ///     .backgroundImage(
    ///         url: "/images/hero.jpg",
    ///         size: .cover,
    ///         position: .center,
    ///         repeat: .noRepeat
    ///     )
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `background-image`, `background-size`, `background-position`,
    /// `background-repeat`, and `background-clip` properties on the rendered element.
    ///
    /// - Parameters:
    ///   - url: The URL path of the background image.
    ///   - size: Optional background sizing mode. Defaults to `nil`.
    ///   - position: Optional background alignment. Defaults to `nil`.
    ///   - repeatMode: Optional repeat mode controlling tiling. Defaults to `nil`.
    ///   - clip: Optional painting area. Defaults to `nil`.
    /// - Returns: A `ModifiedNode` with the background image modifier applied.
    public func backgroundImage(
        url: String, size: BackgroundSize? = nil, position: BackgroundPosition? = nil, repeat repeatMode: BackgroundRepeat? = nil, clip: BackgroundClip? = nil
    )
        -> ModifiedNode<Self>
    {
        let mod = BackgroundImageModifier(url: url, size: size, position: position, repeatMode: repeatMode, clip: clip)
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
