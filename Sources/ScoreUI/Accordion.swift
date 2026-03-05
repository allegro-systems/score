import ScoreCore

/// A single collapsible item within an ``Accordion``.
///
/// Each `AccordionItem` wraps a native HTML `<details>` / `<summary>`
/// pair, providing an accessible disclosure widget that can be expanded
/// or collapsed independently. Use it as a direct child of ``Accordion``.
///
/// The trigger area accepts arbitrary content via a `@NodeBuilder`
/// closure, so you can include icons, badges, or other inline elements
/// alongside the title text.
///
/// ### Example
///
/// ```swift
/// AccordionItem(open: true) {
///     Text(verbatim: "What is Score?")
/// } content: {
///     Paragraph { Text(verbatim: "A Swift web framework.") }
/// }
/// ```
public struct AccordionItem<Trigger: Node, Content: Node>: Component {

    /// Whether the item is expanded when the page first renders.
    public let isOpen: Bool

    /// The visible heading content that toggles the item open or closed.
    public let trigger: Trigger

    /// The content revealed when the item is open.
    public let content: Content

    /// Creates an accordion item with custom trigger content.
    ///
    /// - Parameters:
    ///   - open: Whether the item starts expanded. Defaults to `false`.
    ///   - trigger: A `@NodeBuilder` closure that produces the clickable
    ///     heading content (text, icons, badges, etc.).
    ///   - content: A `@NodeBuilder` closure that produces the body
    ///     content shown when expanded.
    public init(
        open: Bool = false,
        @NodeBuilder trigger: () -> Trigger,
        @NodeBuilder content: () -> Content
    ) {
        self.isOpen = open
        self.trigger = trigger()
        self.content = content()
    }

    public var body: some Node {
        Details(
            open: isOpen,
            summary: {
                Summary { trigger }
                    .dataAttribute("part", "trigger")
            },
            content: {
                Stack {
                    content
                }
                .dataAttribute("part", "content")
            }
        )
        .dataAttribute("part", "item")
        .dataAttribute("state", isOpen ? "open" : "closed")
    }
}

extension AccordionItem where Trigger == Text<TextNode> {

    /// Creates an accordion item with a plain string title.
    ///
    /// This convenience initialiser preserves the original string-based API.
    ///
    /// - Parameters:
    ///   - title: The clickable heading text.
    ///   - open: Whether the item starts expanded. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure that produces the body
    ///     content shown when expanded.
    public init(
        title: String,
        open: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.isOpen = open
        self.trigger = Text(verbatim: title)
        self.content = content()
    }
}

/// A vertically stacked set of collapsible disclosure items.
///
/// `Accordion` groups one or more ``AccordionItem`` children into a
/// semantic container. Each item independently expands and collapses
/// using native HTML `<details>` elements.
///
/// ### Example
///
/// ```swift
/// Accordion {
///     AccordionItem(title: "Getting Started") {
///         Text(verbatim: "Install the package...")
///     }
///     AccordionItem(title: "Configuration") {
///         Text(verbatim: "Add a score.json file...")
///     }
/// }
/// ```
public struct Accordion<Content: Node>: Component {

    /// The ``AccordionItem`` children that form the disclosure group.
    public let content: Content

    /// Creates an accordion with the given items.
    ///
    /// - Parameter content: A `@NodeBuilder` closure providing
    ///   ``AccordionItem`` children.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .dataAttribute("component", "accordion")
        .accessibility(role: "group")
    }
}
