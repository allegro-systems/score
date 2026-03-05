import ScoreCore

/// A labeled range slider input.
///
/// `Slider` pairs a ``Label`` with a range ``Input``, providing
/// an accessible control for selecting a numeric value within a range.
///
/// ### Example
///
/// ```swift
/// Slider(name: "volume", label: "Volume", min: "0", max: "100", value: "50")
/// ```
public struct Slider: Component {

    /// The form field name.
    public let name: String

    /// The visible label text.
    public let label: String

    /// The minimum value as a string.
    public let min: String?

    /// The maximum value as a string.
    public let max: String?

    /// The current value as a string.
    public let value: String?

    /// Whether the slider is disabled.
    public let isDisabled: Bool

    /// Creates a slider.
    ///
    /// - Parameters:
    ///   - name: The form field name.
    ///   - label: The visible label text.
    ///   - min: The minimum value. Defaults to `nil`.
    ///   - max: The maximum value. Defaults to `nil`.
    ///   - value: The initial value. Defaults to `nil`.
    ///   - disabled: Whether the slider is disabled. Defaults to `false`.
    public init(
        name: String,
        label: String,
        min: String? = nil,
        max: String? = nil,
        value: String? = nil,
        disabled: Bool = false
    ) {
        self.name = name
        self.label = label
        self.min = min
        self.max = max
        self.value = value
        self.isDisabled = disabled
    }

    public var body: some Node {
        Stack {
            Label(for: "slider-\(name)") {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "label")
            Input(
                type: .range,
                name: name,
                value: value,
                id: "slider-\(name)",
                disabled: isDisabled,
                min: min,
                max: max
            )
            .htmlAttribute("data-part", "track")
        }
        .htmlAttribute("data-component", "slider")
    }
}
