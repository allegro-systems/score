import ScoreCore

// MARK: - NavBarBrand

/// The brand/logo area of a ``NavBar``.
///
/// `NavBarBrand` accepts arbitrary content — text, images, icons, or any
/// combination — and renders it as a linked area at the leading edge of
/// the navigation bar.
///
/// ### Example
///
/// ```swift
/// NavBarBrand(href: "/") {
///     Image(src: "/logo.svg", alt: "Acme")
///     Text(verbatim: "Acme")
/// }
/// ```
public struct NavBarBrand<Content: Node>: Component {

    /// The destination URL when the brand area is clicked.
    public let href: String

    /// The brand content (logo, text, icon, etc.).
    public let content: Content

    /// Creates a brand area.
    ///
    /// - Parameters:
    ///   - href: The destination URL. Defaults to `"/"`.
    ///   - content: A `@NodeBuilder` closure producing the brand content.
    public init(
        href: String = "/",
        @NodeBuilder content: () -> Content
    ) {
        self.href = href
        self.content = content()
    }

    public var body: some Node {
        Link(to: href) {
            content
        }
        .htmlAttribute("data-part", "brand")
    }
}

// MARK: - NavBarContent

/// The main navigation items area of a ``NavBar``.
///
/// Typically contains ``NavItem`` children arranged in a horizontal list.
///
/// ### Example
///
/// ```swift
/// NavBarContent {
///     NavItem(href: "/") { Text(verbatim: "Home") }
///     NavItem(href: "/docs") { Text(verbatim: "Docs") }
/// }
/// ```
public struct NavBarContent<Content: Node>: Component {

    /// The navigation items.
    public let content: Content

    /// Creates a content area.
    ///
    /// - Parameter content: A `@NodeBuilder` closure providing ``NavItem`` children.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        UnorderedList {
            content
        }
        .htmlAttribute("data-part", "content")
    }
}

// MARK: - NavBarActions

/// The trailing actions area of a ``NavBar``.
///
/// Use this slot for buttons, search fields, user menus, and other
/// interactive controls that sit at the end of the navigation bar.
///
/// ### Example
///
/// ```swift
/// NavBarActions {
///     StyledButton(.ghost) { Text(verbatim: "Sign In") }
///     StyledButton(.default) { Text(verbatim: "Sign Up") }
/// }
/// ```
public struct NavBarActions<Content: Node>: Component {

    /// The action content.
    public let content: Content

    /// Creates an actions area.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the actions.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-part", "actions")
    }
}

// MARK: - NavItem

/// A single navigation link within a ``NavBar``.
///
/// `NavItem` accepts arbitrary content for its label — text, icons,
/// badges, or any combination.
///
/// ### Example
///
/// ```swift
/// NavItem(href: "/") {
///     Text(verbatim: "Home")
/// }
///
/// NavItem(href: "/docs", isActive: true) {
///     Image(src: "/icons/book.svg", alt: "")
///     Text(verbatim: "Docs")
/// }
/// ```
public struct NavItem<Content: Node>: Component {

    /// The destination URL.
    public let href: String

    /// Whether this item represents the current page.
    public let isActive: Bool

    /// The content rendered inside the navigation link.
    public let content: Content

    /// Creates a navigation item.
    ///
    /// - Parameters:
    ///   - href: The destination URL.
    ///   - isActive: Whether this item is the active page. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the item's label content.
    public init(
        href: String,
        isActive: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.href = href
        self.isActive = isActive
        self.content = content()
    }

    public var body: some Node {
        ListItem {
            Link(to: href) {
                content
            }
        }
        .htmlAttribute("data-state", isActive ? "active" : "inactive")
    }
}

// MARK: - NavBar

/// A top-level navigation bar component.
///
/// `NavBar` renders as a `<header>` containing a `<nav>` with composable
/// sub-parts: ``NavBarBrand``, ``NavBarContent``, and ``NavBarActions``.
/// Each sub-part is independently styleable and optional.
///
/// The navigation bar references theme component tokens (`--navbar-*`)
/// for its default styling, so changing the theme automatically updates
/// all navigation bars.
///
/// ### Example
///
/// ```swift
/// NavBar {
///     NavBarBrand {
///         Image(src: "/logo.svg", alt: "Score")
///         Text(verbatim: "Score")
///     }
///     NavBarContent {
///         NavItem(href: "/", isActive: true) { Text(verbatim: "Home") }
///         NavItem(href: "/docs") { Text(verbatim: "Docs") }
///         NavItem(href: "/blog") { Text(verbatim: "Blog") }
///     }
///     NavBarActions {
///         StyledButton(.ghost) { Text(verbatim: "Login") }
///     }
/// }
/// ```
public struct NavBar<Content: Node>: Component {

    /// The navigation bar content (brand, items, actions).
    public let content: Content

    /// Creates a navigation bar.
    ///
    /// - Parameter content: A `@NodeBuilder` closure providing
    ///   ``NavBarBrand``, ``NavBarContent``, and/or ``NavBarActions``.
    public init(
        @NodeBuilder content: () -> Content
    ) {
        self.content = content()
    }

    public var body: some Node {
        Header {
            Navigation {
                content
            }
        }
        .htmlAttribute("data-component", "navbar")
    }
}
