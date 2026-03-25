/// A protocol for extending Score applications with additional capabilities.
///
/// Plugins provide a modular way to add frontend resources, backend routes,
/// and other functionality to a Score application without modifying the core
/// framework. Each plugin declares the resources it needs, and the runtime
/// wires them into the build and serving pipelines automatically.
///
/// ### Frontend plugins
///
/// Frontend plugins inject stylesheets, scripts, and components:
///
/// ```swift
/// struct LucidePlugin: ScorePlugin {
///     var name: String { "Lucide Icons" }
///     var stylesheetImports: [String] {
///         ["https://unpkg.com/lucide-static@latest/font/lucide.css"]
///     }
/// }
/// ```
///
/// ### Backend plugins
///
/// Backend plugins provide controllers that handle API routes:
///
/// ```swift
/// struct StripePlugin: ScorePlugin {
///     var name: String { "Stripe" }
///     var controllers: [any Controller] {
///         [StripeWebhookController(apiKey: apiKey)]
///     }
/// }
/// ```
///
/// ### Registration
///
/// Register plugins in your ``Application``:
///
/// ```swift
/// @main
/// struct MySite: Application {
///     var plugins: [any ScorePlugin] {
///         [LucidePlugin(), StripePlugin(apiKey: "sk_...")]
///     }
/// }
/// ```
public protocol ScorePlugin: Sendable {

    /// A human-readable name for this plugin.
    var name: String { get }

    // MARK: - Frontend Resources

    /// External stylesheet URLs to import.
    ///
    /// These are emitted as `@import url(...)` rules in the generated
    /// `global.css`, alongside the theme's own stylesheet imports.
    var stylesheetImports: [String] { get }

    /// Inline CSS to append to the theme stylesheet.
    ///
    /// Use this for plugin-specific styles that don't warrant a separate
    /// stylesheet URL.
    var inlineCSS: String? { get }

    /// External script URLs to include before `</body>`.
    var scriptLinks: [String] { get }

    // MARK: - Backend

    /// Controllers providing API routes.
    ///
    /// Plugin controllers are merged with the application's own controllers
    /// when building the route table.
    var controllers: [any Controller] { get }
}

extension ScorePlugin {
    public var stylesheetImports: [String] { [] }
    public var inlineCSS: String? { nil }
    public var scriptLinks: [String] { [] }
    public var controllers: [any Controller] { [] }
}
