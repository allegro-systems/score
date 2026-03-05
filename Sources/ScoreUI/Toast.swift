import ScoreCore

/// The semantic variant of a ``Toast`` notification.
public enum ToastVariant: String, Sendable {

    /// A neutral informational toast.
    case info

    /// A toast indicating success.
    case success

    /// A toast indicating a warning.
    case warning

    /// A toast indicating an error.
    case error
}

/// A title sub-component for use inside a ``Toast``.
///
/// Renders with the `data-part="title"` attribute and semibold weight.
///
/// ### Example
///
/// ```swift
/// Toast(.success) {
///     ToastTitle { "Saved" }
///     ToastDescription { "Your changes have been saved." }
/// }
/// ```
public struct ToastTitle<Content: Node>: Component {

    /// The title content.
    public let content: Content

    /// Creates a toast title.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the title text.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-part", "title")
    }
}

/// A description sub-component for use inside a ``Toast``.
///
/// Renders with the `data-part="description"` attribute and muted color.
///
/// ### Example
///
/// ```swift
/// Toast(.error) {
///     ToastTitle { "Error" }
///     ToastDescription { "Failed to save changes." }
/// }
/// ```
public struct ToastDescription<Content: Node>: Component {

    /// The description content.
    public let content: Content

    /// Creates a toast description.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the
    ///   description text.
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

/// An action sub-component for use inside a ``Toast``.
///
/// Renders a button with the `data-part="action"` attribute.
///
/// ### Example
///
/// ```swift
/// Toast(.info) {
///     ToastTitle { "Update available" }
///     ToastDescription { "A new version is ready." }
///     ToastAction { "Install" }
/// }
/// ```
public struct ToastAction<Content: Node>: Component {

    /// The action content.
    public let content: Content

    /// Creates a toast action.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the
    ///   action label.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Button {
            content
        }
        .htmlAttribute("data-part", "action")
    }
}

/// A brief notification message that appears temporarily.
///
/// `Toast` renders as an accessible status region. The Score runtime
/// handles the timing and dismissal animation. Compose with
/// ``ToastTitle``, ``ToastDescription``, and ``ToastAction`` for
/// structured content.
///
/// ### Example
///
/// ```swift
/// Toast(.success) {
///     ToastTitle { "Saved" }
///     ToastDescription { "Changes saved successfully." }
/// }
/// ```
public struct Toast<Content: Node>: Component {

    /// The semantic variant of the toast.
    public let variant: ToastVariant

    /// The notification content.
    public let content: Content

    /// Creates a toast notification.
    ///
    /// - Parameters:
    ///   - variant: The semantic variant. Defaults to `.info`.
    ///   - content: A `@NodeBuilder` closure producing the toast message.
    public init(
        _ variant: ToastVariant = .info,
        @NodeBuilder content: () -> Content
    ) {
        self.variant = variant
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-component", "toast")
        .htmlAttribute("data-variant", variant.rawValue)
        .accessibility(role: "status")
    }
}
