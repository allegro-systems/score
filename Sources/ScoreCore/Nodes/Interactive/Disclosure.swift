/// A node that provides the visible heading for a ``Details`` disclosure widget.
///
/// `Summary` renders as the HTML `<summary>` element. It must be the first
/// child of a ``Details`` node and acts as its always-visible, clickable
/// toggle label. When the user clicks the summary, the browser expands or
/// collapses the remaining content of the enclosing ``Details`` element.
///
/// ### Example
///
/// ```swift
/// Details(summary: {
///     Summary { "What is Score?" }
/// }) {
///     Paragraph { "Score is a Swift DSL for building HTML documents." }
/// }
/// ```
///
/// - Important: If a ``Details`` element does not contain a `Summary`, the
///   browser renders a default label (typically "Details"). Always supply a
///   meaningful `Summary` to make the disclosure widget understandable.
public struct Summary<Content: Node>: Node {

    /// The label content displayed as the clickable toggle for the enclosing
    /// ``Details`` element.
    public let content: Content

    /// Creates a summary label for a ``Details`` disclosure widget.
    ///
    /// - Parameter content: A node builder closure providing the visible heading text
    ///     or inline content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a native disclosure widget with a collapsible body.
///
/// `Details` renders as the HTML `<details>` element. It pairs with a
/// ``Summary`` child to produce an accordion-style disclosure control: the
/// summary is always visible and acts as a toggle; the rest of the content is
/// shown or hidden depending on the `open` state. No JavaScript is required
/// for basic expand/collapse behaviour.
///
/// Typical uses include:
/// - FAQ sections where each question expands to reveal an answer
/// - Collapsible filter panels in a search interface
/// - Progressive disclosure of advanced settings
///
/// ### Example
///
/// ```swift
/// Details(summary: {
///     Summary { "System Requirements" }
/// }) {
///     UnorderedList {
///         ListItem { "macOS 13 or later" }
///         ListItem { "4 GB RAM minimum" }
///     }
/// }
///
/// // Pre-expanded
/// Details(open: true, summary: {
///     Summary { "Release Notes" }
/// }) {
///     Paragraph { "Version 2.0 introduces Swift 6 concurrency support." }
/// }
/// ```
///
/// - Important: The `summary` parameter must build a ``Summary`` node to
///   conform to the HTML specification. Assistive technologies rely on the
///   `<summary>` element to announce the toggle's current state
///   (expanded/collapsed).
public struct Details<SummaryContent: Node, Content: Node>: Node {

    /// Whether the disclosure widget is expanded and its body is visible when
    /// first rendered.
    ///
    /// When `true`, renders the HTML `open` attribute on the `<details>`
    /// element.
    public let isOpen: Bool

    /// The always-visible heading node, typically a ``Summary``, that toggles
    /// the visibility of `content`.
    public let summary: SummaryContent

    /// The body content that is shown when the widget is open and hidden when
    /// it is closed.
    public let content: Content

    /// Creates a disclosure widget.
    ///
    /// - Parameters:
    ///   - open: When `true`, the widget is rendered in the expanded state.
    ///     Defaults to `false`.
    ///   - summary: A node builder closure providing a ``Summary`` node that
    ///     serves as the clickable toggle label.
    ///   - content: A node builder closure providing the body content shown
    ///     when the widget is expanded.
    public init(
        open: Bool = false,
        @NodeBuilder summary: () -> SummaryContent,
        @NodeBuilder content: () -> Content
    ) {
        self.isOpen = open
        self.summary = summary()
        self.content = content()
    }

    public var body: Never { fatalError() }
}
