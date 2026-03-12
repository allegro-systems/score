/// A node that renders a hyperlink, navigating the user to another resource.
///
/// `Link` renders as the HTML `<a>` (anchor) element. It wraps arbitrary
/// content — text, images, or composed nodes — and makes the entire area
/// clickable, directing the browser to the specified `destination` URL when
/// activated.
///
/// Typical uses include:
/// - Navigating to another page within the same site
/// - Linking to an external website or resource
/// - Providing a mailto or tel link for contact information
///
/// ### Example
///
/// ```swift
/// Link(to: "https://example.com") {
///     "Visit Example"
/// }
///
/// // Image link
/// Link(to: "/home") {
///     Image(src: "logo.png", alt: "Home")
/// }
///
/// // Email link
/// Link(to: "mailto:hello@example.com") {
///     "Contact us"
/// }
/// ```
///
/// - Important: Always supply meaningful content so that the link's purpose is
///   clear without surrounding context. For image-only links, ensure the image
///   carries a descriptive `alt` attribute so screen readers can announce the
///   link destination.
public struct Link<Content: Node>: Node, SourceLocatable {

    /// The URL or path that the link navigates to when activated.
    ///
    /// Rendered as the HTML `href` attribute. Accepts absolute URLs
    /// (e.g. `"https://example.com"`), root-relative paths (e.g. `"/about"`),
    /// document-relative paths, fragment identifiers (e.g. `"#section"`), and
    /// special schemes such as `"mailto:"` and `"tel:"`.
    public let destination: String

    /// The content rendered inside the anchor element.
    ///
    /// The entire content area is interactive and activates the link when
    /// clicked or tapped.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a hyperlink that navigates to the given destination.
    public init(
        to destination: String,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.destination = destination
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}
