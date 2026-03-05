import ScoreCore

/// A labeled progress bar component.
///
/// `ProgressBar` wraps the core ``Progress`` node with an optional
/// visible label, providing a higher-level component for displaying
/// task completion.
///
/// ### Example
///
/// ```swift
/// ProgressBar(value: 65, max: 100, label: "Upload progress")
/// ProgressBar()  // Indeterminate
/// ```
public struct ProgressBar: Component {

    /// The current progress value, or `nil` for an indeterminate bar.
    public let value: Double?

    /// The maximum progress value representing 100% completion.
    public let max: Double?

    /// An optional visible label displayed alongside the bar.
    public let label: String?

    /// Creates a progress bar.
    ///
    /// - Parameters:
    ///   - value: The current progress. Pass `nil` for indeterminate.
    ///     Defaults to `nil`.
    ///   - max: The value representing full completion. Defaults to `nil`.
    ///   - label: Optional visible label text. Defaults to `nil`.
    public init(
        value: Double? = nil,
        max: Double? = nil,
        label: String? = nil
    ) {
        self.value = value
        self.max = max
        self.label = label
    }

    public var body: some Node {
        Stack {
            if let label {
                Label {
                    Text(verbatim: label)
                }
                .htmlAttribute("data-part", "label")
            }
            Stack {
                Progress(value: value, max: max)
                    .htmlAttribute("data-part", "fill")
            }
            .htmlAttribute("data-part", "track")
        }
        .htmlAttribute("data-component", "progress")
        .htmlAttribute("data-state", value == nil ? "indeterminate" : "determinate")
    }
}
