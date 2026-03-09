/// A protocol that represents a server-rendered HTML page at a specific URL path.
///
/// `Page` is the primary abstraction for declaring the content of a URL in a
/// Score application. Each conforming type provides a static `path` that the
/// runtime maps to an HTTP GET handler, and a `body` built with `@NodeBuilder`
/// that describes the complete node tree rendered as the HTML response.
/// Pages may also override application-level metadata.
///
/// Pages are collected by `Application.pages` and registered with the server
/// at startup. The runtime renders each page's `body` to HTML whenever a
/// request arrives for its `path`.
///
/// Typical uses include:
/// - Defining the home page, about page, and other top-level routes
/// - Composing `Component` types to build complex layouts
/// - Rendering dynamic content from controllers or database entities
///
/// ### Example
///
/// ```swift
/// struct HomePage: Page {
///     static let path = "/"
///
///     var body: some Node {
///         Stack {
///             Heading(.one) { "Welcome to Score" }
///             Paragraph { "Build server-rendered Swift web apps." }
///             Link(to: "/about") { "Learn more" }
///         }
///     }
/// }
///
/// struct AboutPage: Page {
///     static let path = "/about"
///     var metadata: (any Metadata)? { SiteMetadata(title: "About") }
///
///     var body: some Node {
///         Heading(.one) { "About" }
///         Paragraph { "Score is a Swift web framework." }
///     }
/// }
/// ```
///
/// ### Protocol Conformance Requirements
///
/// A type conforming to `Page` must:
/// - Declare a `static var path: String` representing the URL this
///   page is served at (e.g. `"/"`, `"/about"`, `"/blog/posts"`).
/// - Optionally declare `var metadata: (any Metadata)?` to patch
///   application-level metadata.
/// - Implement `var body: Body { get }` annotated with `@NodeBuilder`, where
///   `Body` is any concrete `Node` type, typically expressed as `some Node`.
/// - Satisfy `Sendable` so that page instances can be shared across async
///   rendering tasks.
public protocol Page: Sendable {

    /// The concrete `Node` type that forms the root of this page's content tree.
    ///
    /// In most cases this is expressed as `some Node` using an opaque return
    /// type, allowing the compiler to infer the underlying type from `body`.
    associatedtype Body: Node

    /// The URL path at which this page is served.
    ///
    /// The value should begin with a leading `/` and must be unique across all
    /// pages registered with the same `Application`. The runtime maps incoming
    /// GET requests for this path to the page's rendered `body`.
    ///
    /// ### Example
    ///
    /// ```swift
    /// static let path = "/blog/posts"
    /// ```
    static var path: String { get }

    /// The resolved path for this page instance.
    ///
    /// Defaults to `Self.path`. Override on dynamic page types (such as
    /// content-driven pages) where each instance serves a different URL.
    var path: String { get }

    /// An optional page-level metadata override.
    ///
    /// When `nil`, the page inherits `Application.metadata` unchanged.
    var metadata: (any Metadata)? { get }

    /// The root node tree that defines the HTML content of this page.
    ///
    /// Use `@NodeBuilder` closure syntax to compose multiple child nodes.
    /// The returned value is rendered to an HTML string by the Score runtime
    /// and sent as the HTTP response body.
    @NodeBuilder
    var body: Body { get }
}

extension Page {

    /// An optional page-level metadata override.
    ///
    /// The default implementation returns `nil`, so pages inherit
    /// `Application.metadata` unchanged unless they explicitly override this.
    public var metadata: (any Metadata)? { nil }

    /// The resolved path for this page instance.
    ///
    /// Returns `Self.path` by default, so standard pages work unchanged.
    public var path: String { Self.path }
}
