/// A protocol for third-party service integrations.
///
/// `Vendor` provides a standard interface for plugging external APIs
/// (analytics, payments, email, etc.) into a Score application. Each
/// vendor declares its own set of routes that are registered alongside
/// the application's controllers.
///
/// ### Example
///
/// ```swift
/// struct StripeVendor: Vendor {
///     let apiKey: String
///
///     var routes: [Route] {
///         [
///             Route(method: .post, path: "/stripe/checkout"),
///             Route(method: .post, path: "/stripe/webhook"),
///         ]
///     }
/// }
/// ```
public protocol Extension: Sendable {

    /// The routes this vendor exposes.
    ///
    /// These routes are registered with the application's router at startup,
    /// alongside page routes and controller routes.
    var routes: [Route] { get }
}
