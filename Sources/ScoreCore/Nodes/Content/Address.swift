/// A node that renders contact information for its nearest sectioning ancestor.
///
/// `Address` wraps its children in an HTML `<address>` element, which is
/// intended to supply contact information for the nearest ``Article`` or
/// ``Body`` ancestor. Typical content includes a physical mailing address,
/// an email link, a phone number, or links to social-media profiles.
///
/// Renders as the HTML `<address>` element.
///
/// ### Example — page-level contact block
///
/// ```swift
/// Address {
///     Text { "Score Project" }
///     LineBreak()
///     Text { "hello@scoreproject.dev" }
/// }
/// ```
///
/// ### Example — author contact inside an article
///
/// ```swift
/// Article {
///     Heading(.one) { Text { "Release Notes" } }
///     Address {
///         Text { "Written by " }
///         Strong { Text { "Jane Smith" } }
///         Text { " — jane@example.com" }
///     }
/// }
/// ```
///
/// - Important: `Address` is intended for contact information only, not for
///   marking up arbitrary postal addresses that are unrelated to the document
///   or its nearest section. Do not place headings, sections, or other
///   block-level content (beyond what is appropriate for contact details)
///   inside `Address`.
public struct Address<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<address>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an address node from a node-builder closure.
    ///
    /// Supply inline or simple block content — such as ``Text``, ``LineBreak``,
    /// or anchor links — that describes how to reach the author or owner of
    /// the surrounding section.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Address {
    ///     Text { "support@example.com" }
    /// }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Address` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}
