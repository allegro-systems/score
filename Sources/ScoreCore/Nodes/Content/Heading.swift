/// The importance level of a ``Heading`` node, corresponding to the HTML
/// heading hierarchy from `<h1>` through `<h6>`.
///
/// HTML defines six levels of headings. Level ``one`` is the most prominent
/// and should typically appear once per page as the main title. Levels
/// ``two`` through ``six`` are used for progressively deeper subsections.
///
/// Choosing the correct level is important for accessibility: screen readers
/// and other assistive technologies rely on a well-formed heading hierarchy
/// to help users navigate a document.
///
/// ### Example
///
/// ```swift
/// Heading(.one) { Text(verbatim: "Welcome") }       // renders <h1>
/// Heading(.two) { Text(verbatim: "Introduction") }  // renders <h2>
/// Heading(.three) { Text(verbatim: "Details") }     // renders <h3>
/// ```
public enum HeadingLevel: Int, Sendable {

    /// The top-level heading, rendered as `<h1>`.
    ///
    /// A page should generally contain only one `<h1>`, representing its
    /// primary title or purpose.
    case one = 1

    /// A second-level heading, rendered as `<h2>`.
    ///
    /// Use for major sections that fall directly beneath the page's primary
    /// `<h1>` heading.
    case two = 2

    /// A third-level heading, rendered as `<h3>`.
    ///
    /// Use for subsections within an `<h2>` section.
    case three = 3

    /// A fourth-level heading, rendered as `<h4>`.
    ///
    /// Use for subsections within an `<h3>` section.
    case four = 4

    /// A fifth-level heading, rendered as `<h5>`.
    ///
    /// Use for subsections within an `<h4>` section.
    case five = 5

    /// A sixth-level heading, rendered as `<h6>`.
    ///
    /// The lowest level of heading in the HTML specification. Use sparingly;
    /// if you need more than six levels of nesting, consider restructuring
    /// the document.
    case six = 6
}

/// A node that renders a section heading at a specified level.
///
/// `Heading` wraps its children in one of the six HTML heading elements
/// (`<h1>` through `<h6>`), determined by the ``HeadingLevel`` passed at
/// initialization. Headings convey document structure to both browsers and
/// assistive technologies, so the levels should be used in a logical,
/// non-skipping order.
///
/// Renders as the HTML `<h1>` – `<h6>` element corresponding to the
/// given ``HeadingLevel``.
///
/// ### Example — page title and section headings
///
/// ```swift
/// Heading(.one) {
///     Text(verbatim: "Score Documentation")
/// }
///
/// Heading(.two) {
///     Text(verbatim: "Getting Started")
/// }
///
/// Heading(.three) {
///     Text(verbatim: "Installation")
/// }
/// ```
///
/// - Important: Do not skip heading levels (e.g., jumping from `.one`
///   directly to `.three`) as this harms accessibility and document
///   semantics.
public struct Heading<Content: Node>: Node, SourceLocatable {

    /// The heading level that determines which HTML element is rendered.
    ///
    /// A value of ``HeadingLevel/one`` emits `<h1>`, ``HeadingLevel/two``
    /// emits `<h2>`, and so on up to ``HeadingLevel/six`` which emits `<h6>`.
    public let level: HeadingLevel

    /// The child node that provides the heading's rendered content.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a heading node at the specified level.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Heading(.two) {
    ///     Text(verbatim: "Chapter One")
    /// }
    /// ```
    ///
    public init(
        _ level: HeadingLevel,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.level = level
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Heading` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}
