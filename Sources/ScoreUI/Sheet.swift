import ScoreCore

/// The edge from which a ``Sheet`` slides into view.
public enum SheetSide: String, Sendable {

    /// The sheet slides in from the top edge.
    case top

    /// The sheet slides in from the trailing (right in LTR) edge.
    case right

    /// The sheet slides in from the bottom edge.
    case bottom

    /// The sheet slides in from the leading (left in LTR) edge.
    case left
}

/// A panel that slides in from the edge of the viewport.
///
/// `Sheet` wraps a ``Dialog`` with additional metadata about which
/// edge the panel originates from. The Score theme uses this to
/// apply the correct slide animation.
///
/// ### Example
///
/// ```swift
/// Sheet(.right, open: true) {
///     Heading(.two) { Text(verbatim: "Settings") }
///     Paragraph { Text(verbatim: "Configure your preferences.") }
/// }
/// ```
public struct Sheet<Content: Node>: Component {

    /// The edge the sheet slides in from.
    public let side: SheetSide

    /// Whether the sheet is visible.
    public let isOpen: Bool

    /// The content displayed inside the sheet.
    public let content: Content

    /// Creates a sheet panel.
    ///
    /// - Parameters:
    ///   - side: The edge to slide from. Defaults to `.right`.
    ///   - open: Whether the sheet is visible. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the sheet's content.
    public init(
        _ side: SheetSide = .right,
        open: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.side = side
        self.isOpen = open
        self.content = content()
    }

    public var body: some Node {
        Dialog(open: isOpen) {
            content
        }
        .dataAttribute("component", "sheet")
        .dataAttribute("side", side.rawValue)
        .dataAttribute("state", isOpen ? "open" : "closed")
    }
}
