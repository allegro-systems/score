import ScoreCore

/// A single option within a ``RadioGroup``.
///
/// ### Example
///
/// ```swift
/// RadioOption(value: "small", label: "Small")
/// ```
public struct RadioOption: Sendable {

    /// The value submitted when this option is selected.
    public let value: String

    /// The visible label for this option.
    public let label: String

    /// Creates a radio option.
    ///
    /// - Parameters:
    ///   - value: The form value.
    ///   - label: The visible label text.
    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }
}

/// A group of mutually exclusive radio button options.
///
/// `RadioGroup` renders a `<fieldset>` with a `<legend>` and a set of
/// radio inputs that share the same `name`, ensuring only one can be
/// selected at a time.
///
/// ### Example
///
/// ```swift
/// RadioGroup(
///     name: "size",
///     legend: "Choose a size",
///     selected: "medium",
///     options: [
///         RadioOption(value: "small", label: "Small"),
///         RadioOption(value: "medium", label: "Medium"),
///         RadioOption(value: "large", label: "Large"),
///     ]
/// )
/// ```
public struct RadioGroup: Component {

    /// The shared form field name for all radio inputs.
    public let name: String

    /// The visible legend caption for the group.
    public let legend: String

    /// The value of the pre-selected option, if any.
    public let selected: String?

    /// Whether the entire group is disabled.
    public let isDisabled: Bool

    /// The available radio options.
    public let options: [RadioOption]

    /// Creates a radio group.
    ///
    /// - Parameters:
    ///   - name: The shared form field name.
    ///   - legend: The caption text for the fieldset.
    ///   - selected: The pre-selected option value. Defaults to `nil`.
    ///   - disabled: Whether the group is disabled. Defaults to `false`.
    ///   - options: The available radio options.
    public init(
        name: String,
        legend: String,
        selected: String? = nil,
        disabled: Bool = false,
        options: [RadioOption]
    ) {
        self.name = name
        self.legend = legend
        self.selected = selected
        self.isDisabled = disabled
        self.options = options
    }

    public var body: some Node {
        Fieldset(disabled: isDisabled) {
            Legend { Text(verbatim: legend) }
                .htmlAttribute("data-part", "legend")
            ForEachNode(options) { option in
                Label(for: "radio-\(name)-\(option.value)") {
                    Input(
                        type: .radio,
                        name: name,
                        value: option.value,
                        id: "radio-\(name)-\(option.value)",
                        checked: selected == option.value
                    )
                    .htmlAttribute("data-part", "control")
                    Text(verbatim: option.label)
                }
                .htmlAttribute("data-part", "option")
            }
        }
        .htmlAttribute("data-component", "radio-group")
    }
}
