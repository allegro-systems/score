/// The context passed to an ``ErrorPage`` when the framework renders it.
///
/// `ErrorContext` carries the HTTP status code, a human-readable message,
/// and the request path that triggered the error. The framework creates
/// instances automatically — for example, when no route matches a request
/// (404) or when an unhandled exception occurs in production (500).
///
/// ### Example
///
/// ```swift
/// struct SiteErrorPage: ErrorPage {
///     var context: ErrorContext
///
///     var body: some Node {
///         Heading(.one) { "\(context.statusCode)" }
///         Paragraph { context.message }
///     }
/// }
/// ```
public struct ErrorContext: Sendable, Equatable {

    /// The HTTP status code (e.g. 404, 500).
    public let statusCode: Int

    /// A short description of the error (e.g. "Not Found").
    public let message: String

    /// The request path that triggered the error.
    public let path: String

    /// Creates an error context.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code.
    ///   - message: A short description of the error.
    ///   - path: The request path that triggered the error.
    public init(statusCode: Int, message: String, path: String) {
        self.statusCode = statusCode
        self.message = message
        self.path = path
    }
}
