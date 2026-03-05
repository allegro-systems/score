import ScoreCore

/// The header region of a ``Card``.
///
/// `CardHeader` groups the title, description, and any leading
/// content at the top of a card.
///
/// ### Example
///
/// ```swift
/// CardHeader {
///     CardTitle { "Revenue" }
///     CardDescription { "Last 30 days" }
/// }
/// ```
public struct CardHeader<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Header {
            content
        }
        .htmlAttribute("data-part", "header")
    }
}

/// The title text within a ``CardHeader``.
///
/// ### Example
///
/// ```swift
/// CardTitle { "Monthly Revenue" }
/// ```
public struct CardTitle<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Heading(.three) {
            content
        }
        .htmlAttribute("data-part", "title")
    }
}

/// A short description line within a ``CardHeader``.
///
/// ### Example
///
/// ```swift
/// CardDescription { "Compared to previous period" }
/// ```
public struct CardDescription<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Paragraph {
            content
        }
        .htmlAttribute("data-part", "description")
    }
}

/// The primary body region of a ``Card``.
///
/// ### Example
///
/// ```swift
/// CardContent {
///     Text(verbatim: "$12,450")
/// }
/// ```
public struct CardContent<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-part", "content")
    }
}

/// The footer region of a ``Card``.
///
/// `CardFooter` typically contains actions or supplementary information.
///
/// ### Example
///
/// ```swift
/// CardFooter {
///     Badge(.success) { "+8.2%" }
/// }
/// ```
public struct CardFooter<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Footer {
            content
        }
        .htmlAttribute("data-part", "footer")
    }
}

/// A visually distinct container for grouping related content and actions.
///
/// `Card` is one of the most common layout components. It renders as
/// an `<article>` element and can contain ``CardHeader``, ``CardContent``,
/// and ``CardFooter`` sub-components. Each sub-part is independently
/// styleable.
///
/// Default styles reference theme component tokens (`--card-*`), so
/// changing the theme or overriding `componentStyles` automatically
/// updates all cards.
///
/// ### Example
///
/// ```swift
/// Card {
///     CardHeader {
///         CardTitle { "Revenue this month" }
///         CardDescription { "Compared to last 30 days" }
///     }
///     CardContent {
///         Text(verbatim: "$12,450")
///     }
///     CardFooter {
///         Badge(.success) { "↑ 8.2%" }
///     }
/// }
/// ```
public struct Card<Content: Node>: Component {

    public let content: Content

    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Article {
            content
        }
        .htmlAttribute("data-component", "card")
    }
}
