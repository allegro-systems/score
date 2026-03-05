import ScoreCore

/// The semantic severity of an ``Alert`` message.
///
/// Alert variants control the visual treatment applied by the Score theme,
/// allowing the same component to convey informational, success, warning,
/// or error states.
public enum AlertVariant: String, Sendable {

    /// A neutral informational message.
    case info

    /// A message indicating a successful outcome.
    case success

    /// A cautionary message that requires attention.
    case warning

    /// A critical message indicating an error or failure.
    case destructive
}

/// A title sub-component for use inside an ``Alert``.
///
/// Renders as a level-five heading with the `data-part="title"` attribute.
///
/// ### Example
///
/// ```swift
/// Alert(.destructive) {
///     AlertTitle { "Error" }
///     AlertDescription { "Your session has expired." }
/// }
/// ```
public struct AlertTitle<Content: Node>: Component {

    /// The title content.
    public let content: Content

    /// Creates an alert title.
    ///
    /// - Parameter content: A `@NodeBuilder` closure producing the title text.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some Node {
        Heading(.five) {
            content
        }
        .htmlAttribute("data-part", "title")
    }
}

/// A description sub-component for use inside an ``Alert``.
///
/// Renders as a paragraph with the `data-part="description"` attribute
/// and muted text color.
///
/// ### Example
///
/// ```swift
/// Alert(.warning) {
///     AlertTitle { "Warning" }
///     AlertDescription { "This action cannot be undone." }
/// }
/// ```
public struct AlertDescription<Content: Node>: Component {

    /// The description content.
    public let content: Content

    /// Creates an alert description.
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

/// A prominent callout used to attract user attention.
///
/// `Alert` renders as an accessible region with role `"alert"` and
/// conveys a visual severity through its ``AlertVariant``. Use it
/// to surface status messages, validation errors, or important notices.
///
/// Compose with ``AlertTitle`` and ``AlertDescription`` for structured
/// content:
///
/// ### Example
///
/// ```swift
/// Alert(.destructive) {
///     AlertTitle { "Error" }
///     AlertDescription { "Your session has expired." }
/// }
/// ```
public struct Alert<Content: Node>: Component {

    /// The semantic variant that determines the alert's visual style.
    public let variant: AlertVariant

    /// The message content displayed inside the alert.
    public let content: Content

    /// Creates an alert with the given severity and content.
    ///
    /// - Parameters:
    ///   - variant: The semantic severity. Defaults to `.info`.
    ///   - content: A `@NodeBuilder` closure that produces the alert's
    ///     message content.
    public init(
        _ variant: AlertVariant = .info,
        @NodeBuilder content: () -> Content
    ) {
        self.variant = variant
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-component", "alert")
        .htmlAttribute("data-variant", variant.rawValue)
        .accessibility(role: "alert")
    }
}
