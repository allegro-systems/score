import ScoreCore

/// A single item within a ``Dropdown`` menu.
///
/// The item content is provided via a `@NodeBuilder` closure, allowing
/// icons, badges, or other inline elements alongside the label text.
///
/// ### Example
///
/// ```swift
/// DropdownItem(href: "/edit") {
///     Text(verbatim: "Edit")
/// }
/// DropdownItem {
///     Text(verbatim: "Delete")
/// }
/// ```
public struct DropdownItem<Content: Node>: Component {

    /// An optional link destination. When `nil`, the item acts as a button.
    public let href: String?

    /// Whether this item is disabled.
    public let isDisabled: Bool

    /// The visible content for this menu item.
    public let content: Content

    /// Creates a dropdown item with custom content.
    ///
    /// - Parameters:
    ///   - href: An optional destination URL. Defaults to `nil`.
    ///   - disabled: Whether the item is disabled. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the item's
    ///     visible content.
    public init(
        href: String? = nil,
        disabled: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.href = href
        self.isDisabled = disabled
        self.content = content()
    }

    public var body: some Node {
        ListItem {
            if let href {
                Link(to: href) { content }
            } else {
                Button(disabled: isDisabled) {
                    content
                }
            }
        }
        .dataAttribute("part", "item")
    }
}

extension DropdownItem where Content == Text<TextNode> {

    /// Creates a dropdown item with a plain string label.
    ///
    /// This convenience initialiser preserves the original string-based API.
    ///
    /// - Parameters:
    ///   - label: The visible label text.
    ///   - href: An optional destination URL. Defaults to `nil`.
    ///   - disabled: Whether the item is disabled. Defaults to `false`.
    public init(label: String, href: String? = nil, disabled: Bool = false) {
        self.href = href
        self.isDisabled = disabled
        self.content = Text(verbatim: label)
    }
}

/// A trigger-activated menu that displays a list of actions or links.
///
/// `Dropdown` uses a native `<details>` / `<summary>` pair to create
/// a progressively enhanced dropdown without JavaScript.
///
/// The trigger content is provided via a `@NodeBuilder` closure,
/// allowing icons, avatars, or other custom elements as the toggle.
///
/// ### Example
///
/// ```swift
/// Dropdown {
///     Text(verbatim: "Actions")
/// } content: {
///     DropdownItem(href: "/edit") { Text(verbatim: "Edit") }
///     DropdownItem { Text(verbatim: "Duplicate") }
///     DropdownItem { Text(verbatim: "Delete") }
/// }
/// ```
public struct Dropdown<Trigger: Node, Content: Node>: Component {

    /// The visible content for the dropdown trigger.
    public let trigger: Trigger

    /// The menu items displayed when the dropdown is open.
    public let content: Content

    /// Creates a dropdown menu with custom trigger content.
    ///
    /// - Parameters:
    ///   - trigger: A `@NodeBuilder` closure providing the trigger content.
    ///   - content: A `@NodeBuilder` closure providing ``DropdownItem``
    ///     children.
    public init(
        @NodeBuilder trigger: () -> Trigger,
        @NodeBuilder content: () -> Content
    ) {
        self.trigger = trigger()
        self.content = content()
    }

    public var body: some Node {
        Details(
            summary: {
                Summary { trigger }
                    .dataAttribute("part", "trigger")
            },
            content: {
                Menu {
                    content
                }
                .dataAttribute("part", "content")
            }
        )
        .dataAttribute("component", "dropdown")
    }
}

extension Dropdown where Trigger == Text<TextNode> {

    /// Creates a dropdown menu with a plain string label trigger.
    ///
    /// This convenience initialiser preserves the original string-based API.
    ///
    /// - Parameters:
    ///   - label: The text for the trigger button.
    ///   - content: A `@NodeBuilder` closure providing ``DropdownItem``
    ///     children.
    public init(
        label: String,
        @NodeBuilder content: () -> Content
    ) {
        self.trigger = Text(verbatim: label)
        self.content = content()
    }
}
