/// A protocol that represents the root configuration of a Score application.
///
/// `Application` is the top-level entry point that wires together the page
/// hierarchy, controller routing table, theme contract, and metadata contract
/// for a Score server. At startup the runtime inspects `pages`, `controllers`,
/// `theme`, and `metadata` to construct rendering and request pipelines.
///
/// Typical uses include:
/// - Declaring every `Page` the server should render
/// - Registering `Controller` types that handle API or form endpoints
/// - Defining a global `Theme` used during CSS and design-token emission
/// - Defining default `Metadata` inherited by all pages
/// - Serving as the single source of truth for application structure
///
/// ### Example
///
/// ```swift
/// struct MyApp: Application {
///     var metadata: (any Metadata)? { SiteMetadata(title: "My App") }
///
///     var theme: (any Theme)? { MyTheme(name: "default") }
///
///     var controllers: [any Controller] {
///         [
///             UserController(),
///             PostController(),
///         ]
///     }
///
///     @PageBuilder
///     var pages: [any Page] {
///         HomePage()
///         AboutPage()
///         ContactPage()
///     }
/// }
/// ```
public protocol Application: Sendable {

    /// Creates a new instance of the application.
    ///
    /// Required for `@main` support so the runtime can instantiate the app.
    init()

    /// The pages served by this application.
    ///
    /// The runtime maps each page's `path` to an HTML rendering handler.
    /// Pages are evaluated in the order they appear in this collection.
    var pages: [any Page] { get }

    /// The active application theme used for rendering.
    var theme: (any Theme)? { get }

    /// The default document metadata inherited by pages.
    var metadata: (any Metadata)? { get }

    /// The controllers that provide HTTP request handling for this application.
    ///
    /// Each controller's `base` path and `routes` are registered with the
    /// server's routing table at startup.
    var controllers: [any Controller] { get }

    /// The directory where build output is written.
    ///
    /// The emitter writes rendered HTML, CSS, and JS files into this path.
    /// Defaults to `.score`.
    var outputDirectory: String { get }

    /// The directory where content files (Markdown, etc.) are stored.
    ///
    /// Content files are loaded by ``ContentCollection`` and rendered via
    /// ``MarkdownNode``. Both absolute and relative paths are accepted;
    /// relative paths resolve against the current working directory.
    /// Defaults to `"Content"`.
    var contentDirectory: String { get }
}

extension Application {

    /// The active application theme used for rendering.
    ///
    /// The default implementation returns ``DefaultTheme``, which provides
    /// a complete set of design tokens out of the box.
    public var theme: (any Theme)? { DefaultTheme() }

    /// The default document metadata inherited by pages.
    ///
    /// The default implementation returns `nil`, meaning pages start with no
    /// application-level metadata unless a conforming type provides one.
    public var metadata: (any Metadata)? { nil }

    /// The controllers that provide HTTP request handling for this application.
    ///
    /// The default implementation returns an empty collection, which is
    /// suitable for page-only applications with no controller endpoints.
    public var controllers: [any Controller] { [] }

    /// The directory where build output is written.
    ///
    /// Defaults to `.score`.
    public var outputDirectory: String { ".score" }

    /// The directory where content files are stored.
    ///
    /// Defaults to `"Content"`. Relative paths resolve against the current
    /// working directory.
    public var contentDirectory: String { "Content" }
}
