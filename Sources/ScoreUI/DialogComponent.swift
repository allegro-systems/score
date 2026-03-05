import ScoreCore

/// The header region of a ``DialogBox``.
///
/// Contains the dialog's title and an optional close control.
///
/// ### Example
///
/// ```swift
/// DialogHeader {
///     Text(verbatim: "Confirm Action")
/// }
/// ```
public struct DialogHeader<Content: Node>: Component {

    /// The header content, typically a title.
    public let content: Content

    /// Creates a dialog header.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the
    ///   header content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Header {
            content
        }
        .dataAttribute("part", "header")
    }
}

/// The body region of a ``DialogBox``.
///
/// ### Example
///
/// ```swift
/// DialogBody {
///     Paragraph { Text(verbatim: "Are you sure?") }
/// }
/// ```
public struct DialogBody<Content: Node>: Component {

    /// The body content of the dialog.
    public let content: Content

    /// Creates a dialog body.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the
    ///   body content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .dataAttribute("part", "body")
    }
}

/// The footer region of a ``DialogBox``, typically containing action buttons.
///
/// ### Example
///
/// ```swift
/// DialogFooter {
///     StyledButton(.destructive) { Text(verbatim: "Delete") }
///     StyledButton(.outline) { Text(verbatim: "Cancel") }
/// }
/// ```
public struct DialogFooter<Content: Node>: Component {

    /// The footer content, typically buttons.
    public let content: Content

    /// Creates a dialog footer.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the
    ///   footer content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Footer {
            content
        }
        .dataAttribute("part", "footer")
    }
}

/// A modal dialog box with structured header, body, and footer regions.
///
/// `DialogBox` wraps the core ``Dialog`` node and provides a
/// composable structure with ``DialogHeader``, ``DialogBody``, and
/// ``DialogFooter`` sub-components.
///
/// ### Example
///
/// ```swift
/// DialogBox(open: true) {
///     DialogHeader { Text(verbatim: "Confirm Deletion") }
///     DialogBody { Paragraph { Text(verbatim: "This cannot be undone.") } }
///     DialogFooter {
///         StyledButton(.destructive) { Text(verbatim: "Delete") }
///         StyledButton(.ghost) { Text(verbatim: "Cancel") }
///     }
/// }
/// ```
public struct DialogBox<Content: Node>: Component {

    /// Whether the dialog is visible when rendered.
    @State public var isOpen: Bool

    /// The child nodes, typically ``DialogHeader``, ``DialogBody``, and
    /// ``DialogFooter``.
    public let content: Content

    /// Opens the dialog.
    @Action(js: "isOpen.set(true)")
    public var open = {}

    /// Closes the dialog.
    @Action(js: "isOpen.set(false)")
    public var close = {}

    /// Creates a dialog box.
    ///
    /// - Parameters:
    ///   - open: Whether the dialog is visible. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the dialog's
    ///     structured children.
    public init(
        open: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self._isOpen = State(
            wrappedValue: open,
            effect: "scope.dataset.state = isOpen.get() ? 'open' : 'closed'; scope.querySelector('dialog').open = isOpen.get()"
        )
        self.content = content()
    }

    public var body: some Node {
        Dialog(open: isOpen) {
            content
        }
        .dataAttribute("component", "dialog")
        .dataAttribute("state", isOpen ? "open" : "closed")
    }
}
