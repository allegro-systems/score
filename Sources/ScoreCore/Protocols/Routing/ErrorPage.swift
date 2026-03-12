/// A page rendered by the framework when an HTTP error occurs.
///
/// `ErrorPage` is the Score equivalent of a custom error handler. Conform
/// a type to this protocol and return it from ``Application/errorBody(for:)``
/// to replace the framework's default plain-text error responses with your
/// own styled pages.
///
/// Because `ErrorPage` refines ``Node``, it composes naturally with
/// layouts, components, and the full modifier system.
///
/// ### Example
///
/// ```swift
/// struct SiteErrorPage: ErrorPage {
///     var context: ErrorContext
///
///     var body: some Node {
///         Layout {
///             Heading(.one) { "\(context.statusCode)" }
///             Paragraph { context.message }
///             Link(to: "/") { "Back to Home" }
///         }
///     }
/// }
/// ```
///
/// Register it with your application:
///
/// ```swift
/// struct MyApp: Application {
///     func errorBody(for context: ErrorContext) -> (any Node)? {
///         SiteErrorPage(context: context)
///     }
/// }
/// ```
///
/// ### Framework Behavior
///
/// - **Development server (404):** Renders your error page with HTTP 404.
/// - **Development server (500):** Shows the built-in error overlay for
///   debugging; uses your error page in production.
/// - **Static build:** Generates a `404.html` file that hosting platforms
///   can serve for missing routes.
public protocol ErrorPage: Node {

    /// The error context describing the status code, message, and path.
    var context: ErrorContext { get }

    /// Creates an error page for the given context.
    ///
    /// The framework calls this initializer automatically when it needs
    /// to render an error response.
    init(context: ErrorContext)
}
