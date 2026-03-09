/// A node that renders a modal or non-modal dialog box.
///
/// `Dialog` renders as the HTML `<dialog>` element, providing a native browser
/// overlay that can be shown or hidden. When `open` is `true` the dialog is
/// visible on the page. Dialogs can be used modally (blocking interaction with
/// the rest of the page) or non-modally, depending on how they are opened via
/// JavaScript.
///
/// Typical uses include:
/// - Confirmation prompts before performing destructive actions
/// - Alert messages requiring user acknowledgement
/// - Lightweight forms or contextual settings panels
///
/// ### Example
///
/// ```swift
/// Dialog(open: true) {
///     Heading(.two) { "Confirm Deletion" }
///     Paragraph { "Are you sure you want to delete this item?" }
///     Button(type: .submit) { "Delete" }
///     Button(type: .button) { "Cancel" }
/// }
/// ```
///
/// - Important: On the server side, `open` controls the initial rendered
///   visibility. Browser-side JavaScript (e.g. `dialog.showModal()`) is
///   typically used to open modal dialogs dynamically after page load.
public struct Dialog<Content: Node>: Node {

    /// Whether the dialog is visible when the page is first rendered.
    ///
    /// When `true`, renders the HTML `open` attribute, making the dialog
    /// visible without requiring JavaScript interaction.
    public let isOpen: Bool

    /// The content displayed inside the dialog, such as headings, text, and
    /// action buttons.
    public let content: Content

    /// Creates a dialog element.
    ///
    /// - Parameters:
    ///   - open: When `true`, the dialog is rendered in the visible/open state.
    ///     Defaults to `false`.
    ///   - content: A node builder closure providing the dialog's interior
    ///     content.
    public init(open: Bool = false, @NodeBuilder content: () -> Content) {
        self.isOpen = open
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a list of commands or options presented to the user.
///
/// `Menu` renders as the HTML `<menu>` element. It represents an unordered
/// list of interactive items — typically buttons or links — that form a
/// toolbar or context menu. It is semantically distinct from a navigation list
/// and is intended to group commands the user can invoke.
///
/// Typical uses include:
/// - A toolbar of action buttons (edit, delete, share) within an article
/// - A context menu triggered by a right-click or long press
/// - An inline list of quick-action controls for a card component
///
/// ### Example
///
/// ```swift
/// Menu {
///     ListItem {
///         Button(type: .button) { "Edit" }
///     }
///     ListItem {
///         Button(type: .button) { "Archive" }
///     }
///     ListItem {
///         Button(type: .button) { "Delete" }
///     }
/// }
/// ```
public struct Menu<Content: Node>: Node {

    /// The list items that make up the menu's commands or options.
    public let content: Content

    /// Creates a menu of interactive commands.
    ///
    /// - Parameter content: A node builder closure providing the menu's list items
    ///     and their associated interactive controls.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}
