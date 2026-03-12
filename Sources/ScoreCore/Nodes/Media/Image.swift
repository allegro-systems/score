/// Strategies for loading an image relative to the viewport.
///
/// `ImageLoading` maps directly to the HTML `loading` attribute on the
/// `<img>` element, giving the browser a hint about when to fetch the
/// image resource.
///
/// ### Example
///
/// ```swift
/// Image(src: "hero.jpg", alt: "Hero banner", loading: .lazy)
/// ```
public enum ImageLoading: String, Sendable {

    /// Fetches the image immediately, regardless of viewport visibility.
    ///
    /// Use this for above-the-fold images that must be available as soon as
    /// the page loads. Equivalent to the HTML `loading="eager"` attribute.
    case eager

    /// Defers fetching the image until it is near the viewport.
    ///
    /// Prefer `.lazy` for below-the-fold images to reduce initial page load
    /// time and save bandwidth on pages with many images. Equivalent to the
    /// HTML `loading="lazy"` attribute.
    case lazy
}

/// The decoding strategy the browser should use when processing an image.
///
/// `ImageDecoding` maps to the HTML `decoding` attribute on the `<img>`
/// element, allowing you to hint whether image decoding should block
/// presentation of other content.
///
/// ### Example
///
/// ```swift
/// Image(src: "diagram.png", alt: "System diagram", decoding: .async)
/// ```
public enum ImageDecoding: String, Sendable {

    /// Decodes the image synchronously before presenting subsequent content.
    ///
    /// This is the traditional behaviour and may cause a brief delay in
    /// rendering content that follows the image. Equivalent to
    /// `decoding="sync"`.
    case sync

    /// Decodes the image asynchronously, allowing other content to render
    /// without waiting.
    ///
    /// Use `.async` for large images where decoding latency would otherwise
    /// degrade perceived rendering speed. Equivalent to `decoding="async"`.
    case async

    /// Lets the browser choose the decoding strategy for the current context.
    ///
    /// This is the default browser behaviour when no `decoding` attribute is
    /// present. Equivalent to `decoding="auto"`.
    case auto
}

/// A node that embeds an image into the document.
///
/// `Image` renders as the HTML `<img>` element. It requires both a source URL
/// and an alternative text description. Providing accurate `alt` text is
/// essential for accessibility and for situations where the image cannot be
/// loaded.
///
/// You can optionally specify intrinsic dimensions, a loading strategy, and a
/// decoding hint. Use the `localized` initialiser when the image source should
/// be resolved through the package's localisation system.
///
/// Typical uses include:
/// - Displaying photos, illustrations, and diagrams
/// - Serving responsive images via a parent `Picture` element
/// - Providing a fallback image inside a `Figure`
///
/// ### Example
///
/// ```swift
/// // Basic image
/// Image(src: "/images/logo.png", alt: "Company logo")
///
/// // Image with explicit dimensions and lazy loading
/// Image(
///     src: "/images/banner.jpg",
///     alt: "Promotional banner",
///     width: 1200,
///     height: 400,
///     loading: .lazy,
///     decoding: .async
/// )
///
/// // Localised image whose path is resolved from a resource bundle
/// Image(localized: "hero-image", alt: "Hero illustration")
/// ```
///
/// - Important: Always supply meaningful `alt` text. An empty string is only
///   appropriate for purely decorative images that convey no information.
public struct Image: Node, SourceLocatable {

    /// The URL or path to the image resource.
    ///
    /// When the image was created with the `localized` initialiser this
    /// property holds the localisation key rather than a literal URL.
    public let src: String

    /// A short textual description of the image's content and purpose.
    ///
    /// Screen readers announce this value to users who cannot see the image.
    /// For decorative images that should be ignored by assistive technologies,
    /// pass an empty string.
    public let alt: String

    /// Indicates whether `src` is a localisation key resolved at render time.
    ///
    /// When `true`, the renderer looks up the final URL from the package's
    /// resource bundle using `src` as the key.
    public let isLocalized: Bool

    /// The intrinsic width of the image in CSS pixels, if known.
    ///
    /// Providing both `width` and `height` lets the browser reserve space
    /// before the image loads, preventing layout shift.
    public let width: Int?

    /// The intrinsic height of the image in CSS pixels, if known.
    ///
    /// Providing both `height` and `width` lets the browser reserve space
    /// before the image loads, preventing layout shift.
    public let height: Int?

    /// The loading strategy hint passed to the browser.
    ///
    /// When `nil`, no `loading` attribute is emitted and the browser uses
    /// its default behaviour, which is equivalent to `.eager`.
    public let loading: ImageLoading?

    /// The decoding strategy hint passed to the browser.
    ///
    /// When `nil`, no `decoding` attribute is emitted and the browser uses
    /// its default behaviour, which is equivalent to `.auto`.
    public let decoding: ImageDecoding?
    public let sourceLocation: SourceLocation

    /// Creates an image node with a literal source URL.
    ///
    /// Use this initialiser when the image path is known at compile time and
    /// does not require localisation.
    public init(
        src: String,
        alt: String,
        width: Int? = nil,
        height: Int? = nil,
        loading: ImageLoading? = nil,
        decoding: ImageDecoding? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.src = src
        self.alt = alt
        self.isLocalized = false
        self.width = width
        self.height = height
        self.loading = loading
        self.decoding = decoding
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// Creates an image node whose source URL is resolved from a localisation
    /// resource bundle.
    ///
    /// The renderer uses `key` to look up the actual image URL at render time,
    /// allowing different asset paths to be served per locale.
    public init(
        localized key: String,
        alt: String,
        width: Int? = nil,
        height: Int? = nil,
        loading: ImageLoading? = nil,
        decoding: ImageDecoding? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.src = key
        self.alt = alt
        self.isLocalized = true
        self.width = width
        self.height = height
        self.loading = loading
        self.decoding = decoding
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// `Image` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Image` directly.
    public var body: Never { fatalError() }
}
