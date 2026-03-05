import ScoreCore

/// A single selectable command within a ``CommandPalette``.
///
/// ### Example
///
/// ```swift
/// CommandItem(label: "Open file", shortcut: "Cmd+O")
/// ```
public struct CommandItem: Component {

    /// The visible label for this command.
    public let label: String

    /// An optional keyboard shortcut hint displayed alongside the label.
    public let shortcut: String?

    /// Whether this command is currently disabled.
    public let isDisabled: Bool

    /// Creates a command item.
    ///
    /// - Parameters:
    ///   - label: The command's visible label.
    ///   - shortcut: An optional keyboard shortcut string. Defaults to `nil`.
    ///   - disabled: Whether the command is disabled. Defaults to `false`.
    public init(
        label: String,
        shortcut: String? = nil,
        disabled: Bool = false
    ) {
        self.label = label
        self.shortcut = shortcut
        self.isDisabled = disabled
    }

    public var body: some Node {
        ListItem {
            Button(disabled: isDisabled) {
                Text(verbatim: label)
                if let shortcut {
                    Small { Text(verbatim: shortcut) }
                        .dataAttribute("part", "shortcut")
                }
            }
        }
        .dataAttribute("part", "item")
    }
}

/// A group of related commands within a ``CommandPalette``.
///
/// ### Example
///
/// ```swift
/// CommandGroup(heading: "File") {
///     CommandItem(label: "New", shortcut: "Cmd+N")
///     CommandItem(label: "Open", shortcut: "Cmd+O")
/// }
/// ```
public struct CommandGroup<Content: Node>: Component {

    /// The heading text for this group of commands.
    public let heading: String

    /// The ``CommandItem`` children in this group.
    public let content: Content

    /// Creates a command group.
    ///
    /// - Parameters:
    ///   - heading: The visible group heading.
    ///   - content: A `@NodeBuilder` closure providing ``CommandItem`` children.
    public init(
        heading: String,
        @NodeBuilder content: () -> Content
    ) {
        self.heading = heading
        self.content = content()
    }

    public var body: some Node {
        Stack {
            Heading(.six) { Text(verbatim: heading) }
                .dataAttribute("part", "heading")
            UnorderedList {
                content
            }
            .dataAttribute("part", "list")
        }
        .dataAttribute("part", "group")
    }
}

/// A searchable command palette overlay for keyboard-driven navigation.
///
/// `CommandPalette` renders as a dialog containing a search input and
/// a list of grouped commands. It follows the command palette pattern
/// popularised by VS Code and similar applications.
///
/// ### Example
///
/// ```swift
/// CommandPalette(placeholder: "Type a command...") {
///     CommandGroup(heading: "Navigation") {
///         CommandItem(label: "Go to Dashboard")
///         CommandItem(label: "Go to Settings")
///     }
/// }
/// ```
public struct CommandPalette<Content: Node>: Component {

    /// The placeholder text shown in the search input.
    public let placeholder: String

    /// Whether the command palette is visible.
    public let isOpen: Bool

    /// The ``CommandGroup`` children within the palette.
    public let content: Content

    /// Creates a command palette.
    ///
    /// - Parameters:
    ///   - placeholder: The search input placeholder. Defaults to
    ///     `"Type a command..."`.
    ///   - open: Whether the palette starts visible. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure providing ``CommandGroup``
    ///     children.
    public init(
        placeholder: String = "Type a command...",
        open: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.placeholder = placeholder
        self.isOpen = open
        self.content = content()
    }

    public var body: some Node {
        Dialog(open: isOpen) {
            Stack {
                Input(
                    type: .search,
                    name: "command-search",
                    placeholder: placeholder,
                    id: "command-palette-input"
                )
                .dataAttribute("part", "input")
                content
            }
        }
        .dataAttribute("component", "command")
        .dataAttribute("state", isOpen ? "open" : "closed")
        .accessibility(role: "dialog")
    }
}
