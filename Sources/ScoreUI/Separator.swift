import ScoreCore

/// The orientation of a ``Separator``.
public enum SeparatorOrientation: String, Sendable {

    /// A horizontal divider line.
    case horizontal

    /// A vertical divider line.
    case vertical
}

/// A visual divider used to separate content sections.
///
/// `Separator` renders as an `<hr>` element for horizontal orientation
/// and as a styled `<div>` for vertical orientation. It provides a
/// thematic break between content groups.
///
/// ### Example
///
/// ```swift
/// Separator()
/// Separator(.vertical)
/// ```
public struct Separator: Component {

    /// The orientation of the separator.
    public let orientation: SeparatorOrientation

    /// Creates a separator.
    ///
    /// - Parameter orientation: The orientation. Defaults to `.horizontal`.
    public init(_ orientation: SeparatorOrientation = .horizontal) {
        self.orientation = orientation
    }

    public var body: some Node {
        HorizontalRule()
            .htmlAttribute("data-component", "separator")
            .htmlAttribute("data-orientation", orientation.rawValue)
            .accessibility(role: "separator")
    }
}
