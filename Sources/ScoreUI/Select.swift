import ScoreCore

/// A single option within a ``SelectField``.
///
/// ### Example
///
/// ```swift
/// SelectOption(value: "us", label: "United States")
/// ```
public struct SelectOption: Sendable {

    /// The value submitted when this option is selected.
    public let value: String

    /// The visible label text.
    public let label: String

    /// Creates a select option.
    ///
    /// - Parameters:
    ///   - value: The form value.
    ///   - label: The display text.
    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }
}

/// A labeled drop-down selection field.
///
/// `SelectField` combines a ``Label`` with a ``Select`` control
/// populated from an array of ``SelectOption`` values.
///
/// ### Example
///
/// ```swift
/// SelectField(
///     label: "Country",
///     name: "country",
///     selected: "us",
///     options: [
///         SelectOption(value: "us", label: "United States"),
///         SelectOption(value: "ca", label: "Canada"),
///     ]
/// )
/// ```
public struct SelectField: Component {

    /// The visible label text.
    public let label: String

    /// The form field name.
    public let name: String

    /// The value of the pre-selected option, if any.
    public let selected: String?

    /// Whether the field is required.
    public let isRequired: Bool

    /// Whether the field is disabled.
    public let isDisabled: Bool

    /// The available options.
    public let options: [SelectOption]

    /// Creates a labeled select field.
    ///
    /// - Parameters:
    ///   - label: The visible label text.
    ///   - name: The form field name.
    ///   - selected: The pre-selected option value. Defaults to `nil`.
    ///   - required: Whether selection is required. Defaults to `false`.
    ///   - disabled: Whether the field is disabled. Defaults to `false`.
    ///   - options: The available options.
    public init(
        label: String,
        name: String,
        selected: String? = nil,
        required: Bool = false,
        disabled: Bool = false,
        options: [SelectOption]
    ) {
        self.label = label
        self.name = name
        self.selected = selected
        self.isRequired = required
        self.isDisabled = disabled
        self.options = options
    }

    public var body: some Node {
        Stack {
            Label(for: "select-\(name)") {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "label")
            Select(
                name: name,
                id: "select-\(name)",
                required: isRequired,
                disabled: isDisabled
            ) {
                ForEachNode(options) { option in
                    Option(
                        value: option.value,
                        selected: option.value == selected
                    ) {
                        Text(verbatim: option.label)
                    }
                    .htmlAttribute("data-part", "option")
                }
            }
            .htmlAttribute("data-part", "select")
        }
        .htmlAttribute("data-component", "select")
    }
}
