import ScoreCore

/// A single link within a ``Breadcrumb`` trail.
///
/// Each `BreadcrumbItem` represents one level in the navigation
/// hierarchy. The last item typically has no `href` and is rendered
/// as plain text to indicate the current page.
///
/// ### Example
///
/// ```swift
/// BreadcrumbItem(label: "Home", href: "/")
/// BreadcrumbItem(label: "Products", href: "/products")
/// BreadcrumbItem(label: "Widget", isCurrent: true)
/// ```
public struct BreadcrumbItem: Component {

    /// The visible text for this breadcrumb level.
    public let label: String

    /// The URL this breadcrumb links to, or `nil` for the current page.
    public let href: String?

    /// Whether this item represents the current page.
    public let isCurrent: Bool

    /// Creates a breadcrumb item.
    ///
    /// - Parameters:
    ///   - label: The visible label text.
    ///   - href: The destination URL. Pass `nil` for the active/current item.
    ///   - isCurrent: Whether this item is the current page. Defaults to `false`.
    public init(label: String, href: String? = nil, isCurrent: Bool = false) {
        self.label = label
        self.href = href
        self.isCurrent = isCurrent
    }

    public var body: some Node {
        if isCurrent {
            ListItem {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "item")
            .htmlAttribute("data-state", "current")
            .accessibility(label: "Current page: \(label)")
        } else if let href {
            ListItem {
                Link(to: href) { Text(verbatim: label) }
                Stack {
                    Text(verbatim: "/")
                }
                .htmlAttribute("data-part", "separator")
                .accessibility(hidden: true)
            }
            .htmlAttribute("data-part", "item")
        } else {
            ListItem {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "item")
            .htmlAttribute("data-state", "current")
        }
    }
}

/// A horizontal navigation trail showing the user's location in a hierarchy.
///
/// `Breadcrumb` wraps its children in a `<nav>` element with an
/// accessible `"breadcrumb"` role. Each child should be a
/// ``BreadcrumbItem``.
///
/// ### Example
///
/// ```swift
/// Breadcrumb {
///     BreadcrumbItem(label: "Home", href: "/")
///     BreadcrumbItem(label: "Docs", href: "/docs")
///     BreadcrumbItem(label: "ScoreUI", isCurrent: true)
/// }
/// ```
public struct Breadcrumb<Content: Node>: Component {

    /// The ``BreadcrumbItem`` children that form the navigation trail.
    public let content: Content

    /// Creates a breadcrumb navigation trail.
    ///
    /// - Parameter content: A `@NodeBuilder` closure providing
    ///   ``BreadcrumbItem`` children.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Navigation {
            OrderedList {
                content
            }
        }
        .htmlAttribute("data-component", "breadcrumb")
        .accessibility(label: "Breadcrumb")
    }
}
