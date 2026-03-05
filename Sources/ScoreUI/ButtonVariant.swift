import ScoreCore

/// The visual style of a ``StyledButton``.
///
/// Button variants map to distinct visual treatments in the Score
/// theme while sharing the same underlying `<button>` semantics.
public enum ButtonVariant: String, Sendable {

    /// The primary filled button style.
    case `default`

    /// A button with a visible border but no fill.
    case outline

    /// A button with no border or fill, relying on text alone.
    case ghost

    /// A button styled to indicate a destructive or irreversible action.
    case destructive
}

/// The size of a ``StyledButton``.
///
/// Button sizes provide consistent padding and font sizing that
/// align with the Score design system.
public enum ButtonSize: String, Sendable {

    /// A compact button for tight layouts.
    case small

    /// The standard button size.
    case medium

    /// A larger button for primary calls to action.
    case large
}

/// A themed button component with variant and size support.
///
/// `StyledButton` wraps the core ``Button`` node and exposes
/// ``ButtonVariant`` and ``ButtonSize`` properties that the Score
/// theme translates into CSS classes.
///
/// ### Example
///
/// ```swift
/// StyledButton(.destructive, size: .large) {
///     Text(verbatim: "Delete Account")
/// }
///
/// StyledButton(.outline) {
///     Text(verbatim: "Cancel")
/// }
/// ```
public struct StyledButton<Content: Node>: Component {

    /// The visual variant of the button.
    public let variant: ButtonVariant

    /// The size of the button.
    public let size: ButtonSize

    /// The behavioural type within a form context.
    public let type: ButtonType

    /// Whether the button is non-interactive.
    public let isDisabled: Bool

    /// The content rendered inside the button.
    public let content: Content

    /// Creates a styled button.
    ///
    /// - Parameters:
    ///   - variant: The visual variant. Defaults to `.default`.
    ///   - size: The button size. Defaults to `.medium`.
    ///   - type: The HTML button type. Defaults to `.button`.
    ///   - disabled: Whether the button is disabled. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the button's label.
    public init(
        _ variant: ButtonVariant = .default,
        size: ButtonSize = .medium,
        type: ButtonType = .button,
        disabled: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.variant = variant
        self.size = size
        self.type = type
        self.isDisabled = disabled
        self.content = content()
    }

    public var body: some Node {
        Button(type: type, disabled: isDisabled) {
            content
        }
        .htmlAttribute("data-component", "button")
        .htmlAttribute("data-variant", variant.rawValue)
        .htmlAttribute("data-size", size.rawValue)
    }
}
