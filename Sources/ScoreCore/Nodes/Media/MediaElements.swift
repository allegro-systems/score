/// The category of a text track, corresponding to the HTML `kind` attribute.
///
/// ### Example
///
/// ```swift
/// Track(src: "/subs.vtt", kind: .subtitles, label: "English", languageCode: "en")
/// ```
public enum TrackKind: String, Sendable {

    /// Subtitles providing a translation of dialogue.
    case subtitles

    /// Captions describing all audio, including sound effects.
    case captions

    /// Text descriptions of the video content.
    case descriptions

    /// Chapter titles for navigation.
    case chapters

    /// Machine-readable metadata not displayed to the user.
    case metadata
}

/// A preload hint for media elements, corresponding to the HTML `preload` attribute.
///
/// ### Example
///
/// ```swift
/// Audio(src: "/episode.mp3", preload: .metadata)
/// ```
public enum MediaPreload: String, Sendable {

    /// Do not preload any data.
    case none

    /// Preload only metadata (duration, dimensions, etc.).
    case metadata

    /// Preload the entire media resource.
    case auto
}

/// A node that specifies an alternative media resource for `Picture`, `Audio`,
/// or `Video` elements.
///
/// `Source` renders as the HTML `<source>` element. It is always used as a
/// child of a container such as `Picture`, `Audio`, or `Video`, providing the
/// browser with one candidate resource to evaluate. The browser selects the
/// first `<source>` whose media query and MIME type it supports.
///
/// ### Example
///
/// ```swift
/// Picture {
///     Source(src: "/images/hero.webp", type: "image/webp", media: "(min-width: 800px)")
///     Source(src: "/images/hero.jpg",  type: "image/jpeg")
///     Image(src: "/images/hero.jpg", alt: "Hero image")
/// }
/// ```
public struct Source: Node, SourceLocatable {

    /// The URL of the media resource.
    public let src: String

    /// The MIME type of the media resource.
    ///
    /// May include a codecs parameter, e.g. `"video/mp4; codecs=\"avc1\""`.
    /// When `nil`, no `type` attribute is emitted and the browser infers the
    /// type from the file extension or server response.
    public let type: String?

    /// A media query that must match for the browser to select this source.
    ///
    /// Use standard CSS media query syntax, e.g. `"(min-width: 600px)"`.
    /// When `nil`, no `media` attribute is emitted and the source is always
    /// a candidate.
    public let media: String?
    public let sourceLocation: SourceLocation

    /// Creates a source node for use inside a `Picture`, `Audio`, or `Video`.
    public init(src: String, type: String? = nil, media: String? = nil, file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        self.src = src
        self.type = type
        self.media = media
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// `Source` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Source` directly.
    public var body: Never { fatalError() }
}

/// A node that associates a timed text track with a `Video` or `Audio` element.
///
/// `Track` renders as the HTML `<track>` element. Common uses include
/// subtitles, captions, chapter markers, and metadata cues. At least one
/// `Track` with `kind: .captions` or `kind: .subtitles` should be provided
/// for video content to meet accessibility requirements.
///
/// ### Example
///
/// ```swift
/// Video(src: "/videos/keynote.mp4") {
///     Track(
///         src: "/tracks/keynote-en.vtt",
///         kind: .subtitles,
///         label: "English",
///         languageCode: "en",
///         isDefault: true
///     )
///     Track(
///         src: "/tracks/keynote-fr.vtt",
///         kind: .subtitles,
///         label: "Français",
///         languageCode: "fr"
///     )
/// }
/// ```
public struct Track: Node, SourceLocatable {

    /// The URL of the WebVTT or TTML track file.
    public let src: String

    /// The category of the track, corresponding to the HTML `kind` attribute.
    ///
    /// When `nil`, the browser defaults to `"subtitles"`.
    public let kind: TrackKind?

    /// A human-readable title for the track, shown in the browser's track
    /// selection UI.
    ///
    /// When `nil`, no `label` attribute is emitted.
    public let label: String?

    /// The BCP 47 language tag for the track's language (e.g. `"en"`, `"fr"`).
    ///
    /// Required when `kind` is `"subtitles"`. When `nil`, no `srclang`
    /// attribute is emitted.
    public let languageCode: String?

    /// Whether this track should be enabled by default when the media loads.
    ///
    /// Only one `Track` per media element should set `isDefault` to `true`.
    /// Corresponds to the boolean `default` attribute on `<track>`.
    public let isDefault: Bool
    public let sourceLocation: SourceLocation

    /// Creates a track node for use inside a `Video` or `Audio` element.
    public init(
        src: String, kind: TrackKind? = nil, label: String? = nil, languageCode: String? = nil, isDefault: Bool = false, file: String = #fileID, filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        self.src = src
        self.kind = kind
        self.label = label
        self.languageCode = languageCode
        self.isDefault = isDefault
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// `Track` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Track` directly.
    public var body: Never { fatalError() }
}

/// A node that embeds an audio player into the document.
///
/// `Audio` renders as the HTML `<audio>` element. The audio source can be
/// provided as a direct `src` URL or via one or more `Source` child nodes to
/// offer format alternatives. Use `Track` child nodes to attach captions or
/// descriptions for accessibility.
///
/// ### Example
///
/// ```swift
/// // Simple audio with browser controls
/// Audio(src: "/audio/podcast-ep1.mp3")
///
/// // Audio with multiple format sources and a caption track
/// Audio(controls: true) {
///     Source(src: "/audio/episode.ogg", type: "audio/ogg")
///     Source(src: "/audio/episode.mp3", type: "audio/mpeg")
///     Track(src: "/tracks/episode-en.vtt", kind: .captions, label: "English", languageCode: "en", isDefault: true)
/// }
/// ```
///
/// - Important: Avoid using `autoplay: true` without `muted: true` as most
///   browsers block audible autoplay by default.
public struct Audio<Content: Node>: Node, SourceLocatable {

    /// The URL of the audio resource.
    ///
    /// When `nil`, the browser expects one or more `Source` child nodes that
    /// enumerate candidate resources.
    public let src: String?

    /// Whether the browser should display its built-in playback controls.
    ///
    /// Corresponds to the boolean `controls` attribute. Set to `false` only
    /// when providing a fully custom playback UI.
    public let showsControls: Bool

    /// Whether playback should begin automatically when the page loads.
    ///
    /// Most browsers suppress audible autoplay; combine with `isMuted: true`
    /// for background audio.
    public let autoplays: Bool

    /// Whether the audio should restart from the beginning after it ends.
    ///
    /// Corresponds to the boolean `loop` attribute.
    public let loops: Bool

    /// Whether the audio output should be silenced.
    ///
    /// Setting this to `true` allows autoplay to succeed in browsers that
    /// block audible autoplay.
    public let isMuted: Bool

    /// A hint to the browser about how much of the audio to preload.
    ///
    /// When `nil`, the browser uses its own heuristic.
    public let preload: MediaPreload?

    /// The child node or node tree nested inside the audio element.
    ///
    /// Typically contains `Source` and `Track` nodes.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an audio node.
    public init(
        src: String? = nil, showsControls: Bool = true, autoplays: Bool = false, loops: Bool = false, isMuted: Bool = false, preload: MediaPreload? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content = { EmptyNode() }
    ) {
        self.src = src
        self.showsControls = showsControls
        self.autoplays = autoplays
        self.loops = loops
        self.isMuted = isMuted
        self.preload = preload
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `Audio` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Audio` directly.
    public var body: Never { fatalError() }
}

/// A node that embeds a video player into the document.
///
/// `Video` renders as the HTML `<video>` element. The video source can be
/// provided as a direct `src` URL or via one or more `Source` child nodes to
/// offer format alternatives. Use `Track` child nodes to attach subtitles,
/// captions, or descriptions for accessibility.
///
/// ### Example
///
/// ```swift
/// // Simple video with browser controls and a poster frame
/// Video(
///     src: "/videos/intro.mp4",
///     poster: "/images/intro-poster.jpg",
///     width: 1280,
///     height: 720
/// )
///
/// // Video with multiple sources and subtitle tracks
/// Video(controls: true, width: 1920, height: 1080) {
///     Source(src: "/videos/keynote.webm", type: "video/webm")
///     Source(src: "/videos/keynote.mp4",  type: "video/mp4")
///     Track(src: "/tracks/keynote-en.vtt", kind: .subtitles, label: "English", languageCode: "en", isDefault: true)
/// }
/// ```
///
/// - Important: Always provide at least one `Track` with captions or subtitles
///   for videos that contain meaningful audio content.
public struct Video<Content: Node>: Node, SourceLocatable {

    /// The URL of the video resource.
    ///
    /// When `nil`, the browser expects one or more `Source` child nodes that
    /// enumerate candidate resources.
    public let src: String?

    /// Whether the browser should display its built-in playback controls.
    ///
    /// Corresponds to the boolean `controls` attribute. Set to `false` only
    /// when providing a fully custom playback UI.
    public let showsControls: Bool

    /// Whether playback should begin automatically when the page loads.
    ///
    /// Most browsers require the video to also be muted for autoplay to succeed.
    public let autoplays: Bool

    /// Whether the video should restart from the beginning after it ends.
    ///
    /// Corresponds to the boolean `loop` attribute.
    public let loops: Bool

    /// Whether the audio track of the video should be silenced.
    ///
    /// Required by most browsers to allow autoplaying video.
    public let isMuted: Bool

    /// A hint to the browser about how much of the video to preload.
    ///
    /// When `nil`, the browser uses its own heuristic.
    public let preload: MediaPreload?

    /// The URL of an image to display before the user plays the video.
    ///
    /// Corresponds to the `poster` attribute. When `nil`, the browser
    /// typically shows the first frame of the video.
    public let poster: String?

    /// The display width of the video player in CSS pixels.
    ///
    /// When `nil`, no `width` attribute is emitted and the player sizes itself
    /// to the video's intrinsic width.
    public let width: Int?

    /// The display height of the video player in CSS pixels.
    ///
    /// When `nil`, no `height` attribute is emitted and the player sizes
    /// itself to the video's intrinsic height.
    public let height: Int?

    /// The child node or node tree nested inside the video element.
    ///
    /// Typically contains `Source` and `Track` nodes.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a video node.
    public init(
        src: String? = nil, showsControls: Bool = true, autoplays: Bool = false, loops: Bool = false, isMuted: Bool = false, preload: MediaPreload? = nil, poster: String? = nil,
        width: Int? = nil, height: Int? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content = { EmptyNode() }
    ) {
        self.src = src
        self.showsControls = showsControls
        self.autoplays = autoplays
        self.loops = loops
        self.isMuted = isMuted
        self.preload = preload
        self.poster = poster
        self.width = width
        self.height = height
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `Video` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Video` directly.
    public var body: Never { fatalError() }
}

/// A node that provides multiple image sources for the browser to choose from.
///
/// `Picture` renders as the HTML `<picture>` element. It wraps one or more
/// `Source` nodes alongside a fallback `Image` node. The browser evaluates
/// each `Source` in document order and picks the first one whose media query
/// matches and whose MIME type it supports; if none match, it falls back to
/// the inner `Image`.
///
/// Use `Picture` to serve next-generation formats (WebP, AVIF) with a JPEG or
/// PNG fallback, or to serve differently cropped variants at different viewport
/// sizes.
///
/// ### Example
///
/// ```swift
/// Picture {
///     Source(src: "/images/hero.avif", type: "image/avif")
///     Source(src: "/images/hero.webp", type: "image/webp")
///     Image(src: "/images/hero.jpg", alt: "Hero landscape photo", width: 1600, height: 900)
/// }
/// ```
public struct Picture<Content: Node>: Node, SourceLocatable {

    /// The child node or node tree nested inside the picture element.
    ///
    /// Should contain one or more `Source` nodes followed by a single fallback
    /// `Image` node.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a picture node containing the given content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `Picture` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Picture` directly.
    public var body: Never { fatalError() }
}

/// A node that provides a resolution-independent drawing surface.
///
/// `Canvas` renders as the HTML `<canvas>` element. The actual drawing is
/// performed via JavaScript using the Canvas 2D or WebGL APIs. Any child
/// content is treated as fallback markup shown to browsers that do not support
/// the canvas element.
///
/// ### Example
///
/// ```swift
/// Canvas(width: 800, height: 600) {
///     Text("Your browser does not support the canvas element.")
/// }
/// ```
///
/// - Important: `<canvas>` provides no built-in accessibility information.
///   Ensure fallback content is meaningful and consider exposing an ARIA role
///   and label via the accessibility modifier.
public struct Canvas<Content: Node>: Node, SourceLocatable {

    /// The width of the canvas drawing surface in CSS pixels.
    ///
    /// Defaults to `300` in browsers when `nil`. Providing an explicit value
    /// prevents unintended scaling of drawn content.
    public let width: Int?

    /// The height of the canvas drawing surface in CSS pixels.
    ///
    /// Defaults to `150` in browsers when `nil`. Providing an explicit value
    /// prevents unintended scaling of drawn content.
    public let height: Int?

    /// The fallback child node or node tree rendered inside the canvas element.
    ///
    /// This content is only shown to browsers that do not support `<canvas>`.
    /// Use it to provide a meaningful alternative such as a static image or
    /// descriptive text.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a canvas node with optional dimensions and fallback content.
    public init(
        width: Int? = nil, height: Int? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `Canvas` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Canvas` directly.
    public var body: Never { fatalError() }
}
