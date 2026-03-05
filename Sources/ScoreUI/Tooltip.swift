import ScoreCore

/// The preferred position of a ``Tooltip`` relative to its trigger.
public enum TooltipPosition: String, Sendable {

    /// The tooltip appears above the trigger.
    case top

    /// The tooltip appears below the trigger.
    case bottom

    /// The tooltip appears to the left of the trigger.
    case left

    /// The tooltip appears to the right of the trigger.
    case right
}

/// A small informational popup that appears on hover or focus.
///
/// `Tooltip` wraps its trigger content and attaches a tooltip message
/// that the Score runtime reveals on hover or keyboard focus.
///
/// ### Example
///
/// ```swift
/// Tooltip(text: "Copy to clipboard", position: .top) {
///     Button { Text(verbatim: "Copy") }
/// }
/// ```
public struct Tooltip<Content: Node>: Component {

    /// The tooltip message text.
    public let text: String

    /// The preferred position relative to the trigger.
    public let position: TooltipPosition

    /// The trigger content that the tooltip is attached to.
    public let content: Content

    /// Creates a tooltip.
    ///
    /// - Parameters:
    ///   - text: The tooltip message.
    ///   - position: The preferred position. Defaults to `.top`.
    ///   - content: A `@NodeBuilder` closure producing the trigger element.
    public init(
        text: String,
        position: TooltipPosition = .top,
        @NodeBuilder content: () -> Content
    ) {
        self.text = text
        self.position = position
        self.content = content()
    }

    public var body: some Node {
        Stack {
            Stack {
                content
            }
            .htmlAttribute("data-part", "trigger")
            Stack {
                Text(verbatim: text)
            }
            .htmlAttribute("data-part", "content")
            .htmlAttribute("data-position", position.rawValue)
            .accessibility(role: "tooltip")
        }
        .htmlAttribute("data-component", "tooltip")
    }
}
