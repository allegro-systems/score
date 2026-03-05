import ScoreCore

/// The semantic variant of a ``Badge``.
///
/// Badge variants control the visual treatment applied by the Score
/// theme to convey meaning at a glance.
public enum BadgeVariant: String, Sendable {

    /// A neutral badge with no special emphasis.
    case `default`

    /// A badge indicating a successful or positive state.
    case success

    /// A badge indicating a warning or cautionary state.
    case warning

    /// A badge indicating a destructive or error state.
    case destructive

    /// A badge with a subtle outline style.
    case outline
}

/// A small inline label used to tag, categorise, or indicate status.
///
/// `Badge` renders as a compact, styled inline element and is commonly
/// used inside cards, tables, or navigation items to surface metadata.
///
/// ### Example
///
/// ```swift
/// Badge(.success) { "Active" }
/// Badge(.destructive) { "Overdue" }
/// ```
public struct Badge<Content: Node>: Component {

    /// The visual variant of the badge.
    public let variant: BadgeVariant

    /// The label content displayed inside the badge.
    public let content: Content

    /// Creates a badge.
    ///
    /// - Parameters:
    ///   - variant: The visual variant. Defaults to `.default`.
    ///   - content: A `@NodeBuilder` closure that produces the badge's
    ///     label content.
    public init(
        _ variant: BadgeVariant = .default,
        @NodeBuilder content: () -> Content
    ) {
        self.variant = variant
        self.content = content()
    }

    public var body: some Node {
        Stack {
            content
        }
        .htmlAttribute("data-component", "badge")
        .htmlAttribute("data-variant", variant.rawValue)
    }
}
