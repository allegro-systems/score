/// How a replaced element's content, such as an image or video, is sized within its container.
///
/// `ObjectFit` controls the scaling and cropping behavior of media elements when
/// the intrinsic dimensions of their content do not match the element's rendered size.
///
/// ### CSS Mapping
///
/// Maps to the CSS `object-fit` property.
public enum ObjectFit: String, Sendable {
    /// The content is stretched to fill the element's box, ignoring its aspect ratio.
    ///
    /// CSS equivalent: `object-fit: fill`.
    case fill

    /// The content is scaled to fit within the element's box while preserving its aspect ratio.
    /// The content will not be cropped, and the box may have empty space (letterboxing).
    ///
    /// CSS equivalent: `object-fit: contain`.
    case contain

    /// The content is scaled and cropped to completely cover the element's box
    /// while preserving its aspect ratio. No empty space is left.
    ///
    /// CSS equivalent: `object-fit: cover`.
    case cover

    /// The content is rendered at its intrinsic size, ignoring the element's dimensions.
    ///
    /// CSS equivalent: `object-fit: none`.
    case none

    /// The content is sized as if `none` or `contain` were specified, whichever
    /// results in a smaller rendered size.
    ///
    /// CSS equivalent: `object-fit: scale-down`.
    case scaleDown = "scale-down"
}

/// A modifier that controls how a replaced element's content is sized within its container.
///
/// `ObjectFitModifier` is typically applied to `Image` or `Video` nodes to control
/// whether the content fills, contains, or is cropped to fit the element's box.
///
/// ### Example
///
/// ```swift
/// Image("hero")
///     .objectFit(.cover)
///
/// Thumbnail()
///     .objectFit(.contain)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `object-fit` property on the rendered element.
public struct ObjectFitModifier: ModifierValue {
    /// The fit mode determining how the content is sized within its container.
    public let fit: ObjectFit

    /// Creates an object-fit modifier.
    ///
    /// - Parameter fit: The `ObjectFit` value describing how the content should be scaled or cropped.
    public init(_ fit: ObjectFit) {
        self.fit = fit
    }
}

/// The alignment point of a replaced element's content within its container.
///
/// `ObjectPosition` controls which part of the content is visible when it
/// overflows its container, such as when an image is cropped with
/// `object-fit: cover`.
///
/// ### CSS Mapping
///
/// Maps to the CSS `object-position` property.
public enum ObjectPosition: String, Sendable {
    /// Centres the content in both axes.
    ///
    /// CSS equivalent: `object-position: center`.
    case center

    /// Aligns the content to the top edge.
    ///
    /// CSS equivalent: `object-position: top`.
    case top

    /// Aligns the content to the bottom edge.
    ///
    /// CSS equivalent: `object-position: bottom`.
    case bottom

    /// Aligns the content to the left edge.
    ///
    /// CSS equivalent: `object-position: left`.
    case left

    /// Aligns the content to the right edge.
    ///
    /// CSS equivalent: `object-position: right`.
    case right

    /// Aligns the content to the top-left corner.
    ///
    /// CSS equivalent: `object-position: top left`.
    case topLeft = "top left"

    /// Aligns the content to the top-right corner.
    ///
    /// CSS equivalent: `object-position: top right`.
    case topRight = "top right"

    /// Aligns the content to the bottom-left corner.
    ///
    /// CSS equivalent: `object-position: bottom left`.
    case bottomLeft = "bottom left"

    /// Aligns the content to the bottom-right corner.
    ///
    /// CSS equivalent: `object-position: bottom right`.
    case bottomRight = "bottom right"
}

/// A modifier that sets the alignment point of a replaced element's content within its container.
///
/// ### Example
///
/// ```swift
/// Image("portrait")
///     .objectFit(.cover)
///     .objectPosition(.top)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `object-position` property on the rendered element.
public struct ObjectPositionModifier: ModifierValue {
    /// The position controlling where content is anchored within its container.
    public let position: ObjectPosition

    /// Creates an object-position modifier.
    ///
    /// - Parameter position: The `ObjectPosition` value describing content alignment.
    public init(_ position: ObjectPosition) {
        self.position = position
    }
}

extension Node {
    /// Sets how the content of a replaced element is sized within its container.
    ///
    /// Apply this modifier to `Image` or `Video` nodes to control cropping and scaling.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("cover-photo")
    ///     .objectFit(.cover)
    ///
    /// Logo()
    ///     .objectFit(.contain)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `object-fit` property on the rendered element.
    ///
    /// - Parameter fit: The `ObjectFit` value describing how content is scaled within the element.
    /// - Returns: A `ModifiedNode` with the object-fit modifier applied.
    public func objectFit(_ fit: ObjectFit) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [ObjectFitModifier(fit)])
    }

    /// Sets the alignment of a replaced element's content within its container.
    ///
    /// Use this together with `.objectFit(.cover)` to control which portion
    /// of the image remains visible after cropping.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image("portrait")
    ///     .objectFit(.cover)
    ///     .objectPosition(.top)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `object-position` property on the rendered element.
    ///
    /// - Parameter position: The `ObjectPosition` value describing content alignment.
    /// - Returns: A `ModifiedNode` with the object-position modifier applied.
    public func objectPosition(_ position: ObjectPosition) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [ObjectPositionModifier(position)])
    }
}
