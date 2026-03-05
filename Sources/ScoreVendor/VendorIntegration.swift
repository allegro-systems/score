/// A protocol for vendor integrations that can be registered on an application.
///
/// Conform to `VendorIntegration` to define a third-party service that
/// requires script injection into the rendered document. The page renderer
/// collects scripts from all registered integrations and emits them in the
/// appropriate document location.
///
/// ### Example
///
/// ```swift
/// struct ChatWidget: VendorIntegration {
///     var scripts: [Script] {
///         [Script(src: "https://chat.example.com/widget.js", async: true)]
///     }
/// }
/// ```
public protocol VendorIntegration: Sendable {

    /// The scripts required by this vendor integration.
    ///
    /// These scripts will be injected into the document by the page
    /// renderer during document assembly.
    var scripts: [Script] { get }
}
