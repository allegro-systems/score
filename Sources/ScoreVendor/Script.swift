import ScoreCore

/// A node that declares a third-party script to be injected into the document.
///
/// `Script` is a primitive node that carries metadata about an external
/// JavaScript resource. It is intended to be consumed by the page renderer
/// at document assembly time, where it will be emitted as a `<script>` tag
/// in the appropriate location (typically at the end of `<head>` or before
/// `</body>`).
///
/// Because `Script` is a primitive node with `Body == Never`, the
/// `HTMLRenderer` will silently skip it during normal tree traversal.
/// Higher-level renderers (such as `PageRenderer` in ScoreRuntime) are
/// responsible for collecting `Script` nodes and emitting them.
///
/// ### Example
///
/// ```swift
/// Script(src: "https://cdn.example.com/analytics.js", async: true)
/// ```
public struct Script: Node {

    /// The URL of the external script resource.
    public let src: String

    /// Whether the script should be loaded asynchronously.
    ///
    /// When `true`, the rendered `<script>` tag includes the `async`
    /// attribute, allowing the browser to fetch the script without blocking
    /// document parsing.
    public let isAsync: Bool

    /// Whether the script should be deferred until after the document has
    /// been parsed.
    ///
    /// When `true`, the rendered `<script>` tag includes the `defer`
    /// attribute, causing the browser to execute the script after the
    /// HTML document has been fully parsed.
    public let isDeferred: Bool

    /// Additional HTML attributes to include on the `<script>` tag.
    ///
    /// Use this dictionary for vendor-specific attributes such as
    /// `data-domain`, `data-site-id`, or `crossorigin`.
    public let attributes: [String: String]

    /// Creates a script node for the given external resource.
    ///
    /// - Parameters:
    ///   - src: The URL of the script to load.
    ///   - async: Whether to load the script asynchronously. Defaults to
    ///     `false`.
    ///   - defer: Whether to defer script execution until after document
    ///     parsing. Defaults to `false`.
    ///   - attributes: Additional HTML attributes for the `<script>` tag.
    ///     Defaults to an empty dictionary.
    public init(
        src: String,
        async: Bool = false,
        defer: Bool = false,
        attributes: [String: String] = [:]
    ) {
        self.src = src
        self.isAsync = `async`
        self.isDeferred = `defer`
        self.attributes = attributes
    }

    /// The body of `Script`, which is never accessible at runtime.
    ///
    /// `Script` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}
