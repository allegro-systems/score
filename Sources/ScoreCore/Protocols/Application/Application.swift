import Foundation

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
///     var errorPage: (any ErrorPage.Type)? { SiteErrorPage.self }
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

    /// The directory containing static resources (fonts, images, etc.).
    ///
    /// Files in this directory are fingerprinted and copied to the output
    /// during static site generation, and served directly during development.
    /// Font files (`.woff`, `.woff2`, `.ttf`, `.otf`) referenced by
    /// ``Theme/fontFaces`` automatically generate `@font-face` declarations.
    /// Defaults to `"Resources"`.
    var resourcesDirectory: String { get }

    /// The plugins registered with this application.
    ///
    /// Plugins extend the application with additional stylesheets, scripts,
    /// components, and controllers. Resources from all plugins are merged
    /// into the build pipeline automatically.
    var plugins: [any ScorePlugin] { get }

    /// The custom error page type used for error responses.
    ///
    /// Set this to your ``ErrorPage`` conforming type to replace the
    /// framework's default plain-text error responses with styled pages.
    /// Return `nil` to keep the default behavior.
    ///
    /// ```swift
    /// var errorPage: (any ErrorPage.Type)? { SiteErrorPage.self }
    /// ```
    ///
    /// The framework instantiates this type:
    /// - On the development server when a 404 occurs.
    /// - On the development server for 500 errors in production mode.
    /// - During static site generation to emit a `404.html` file.
    var errorPage: (any ErrorPage.Type)? { get }

    /// The internationalization configuration for this application.
    ///
    /// When set, the static site emitter generates pages for each supported
    /// locale. The default locale's pages are emitted at their original paths
    /// (e.g. `/about`), while other locales are emitted under a locale prefix
    /// (e.g. `/es/about`). The ``LocalizationContext`` is set automatically
    /// during each rendering pass, making translations available to
    /// ``Localized`` nodes and the ``t(_:default:)`` function.
    ///
    /// Return `nil` to disable internationalization (the default).
    ///
    /// ```swift
    /// var localization: Localization? {
    ///     Localization(
    ///         defaultLocale: "en",
    ///         supportedLocales: ["en", "es", "de"],
    ///         translations: [
    ///             "en": ["nav.about": "About"],
    ///             "es": ["nav.about": "Acerca de"],
    ///         ]
    ///     )
    /// }
    /// ```
    var localization: Localization? { get }
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
    /// Defaults to `.score` in development and `"static"` in production
    /// (Stage deploys place built output in a `static/` directory).
    public var outputDirectory: String {
        // When running inside Stage (--listen mode), use "static"
        if ProcessInfo.processInfo.arguments.contains("--listen") {
            return "static"
        }
        return ".score"
    }

    /// The directory where content files are stored.
    ///
    /// Defaults to `"Content"`. Relative paths resolve against the current
    /// working directory.
    public var contentDirectory: String { "Content" }

    /// The directory containing static resources.
    ///
    /// Defaults to `"Resources"`.
    public var resourcesDirectory: String { "Resources" }

    /// The plugins registered with this application.
    ///
    /// Defaults to an empty array.
    public var plugins: [any ScorePlugin] { [] }

    /// Returns `nil`, keeping the framework's default error responses.
    public var errorPage: (any ErrorPage.Type)? { nil }

    /// Returns `nil`, disabling internationalization.
    public var localization: Localization? { nil }
}
