import ScoreCore

/// A labeled checkbox input for toggling a boolean value.
///
/// `Checkbox` pairs a ``Label`` with an ``Input`` of type `.checkbox`,
/// creating an accessible, clickable control.
///
/// ### Example
///
/// ```swift
/// Checkbox(name: "terms", label: "I accept the terms")
/// ```
public struct Checkbox: Component {

    /// The form field name submitted with the checkbox's value.
    public let name: String

    /// The visible label text displayed next to the checkbox.
    public let label: String

    /// The value submitted when the checkbox is checked.
    public let value: String

    /// Whether the checkbox is initially checked.
    public let isChecked: Bool

    /// Whether the checkbox is non-interactive.
    public let isDisabled: Bool

    /// Whether the checkbox must be checked before form submission.
    public let isRequired: Bool

    /// Creates a checkbox.
    ///
    /// - Parameters:
    ///   - name: The form field name.
    ///   - label: The visible label text.
    ///   - value: The value submitted when checked. Defaults to `"on"`.
    ///   - checked: Whether the checkbox starts checked. Defaults to `false`.
    ///   - disabled: Whether the checkbox is disabled. Defaults to `false`.
    ///   - required: Whether the checkbox is required. Defaults to `false`.
    public init(
        name: String,
        label: String,
        value: String = "on",
        checked: Bool = false,
        disabled: Bool = false,
        required: Bool = false
    ) {
        self.name = name
        self.label = label
        self.value = value
        self.isChecked = checked
        self.isDisabled = disabled
        self.isRequired = required
    }

    public var body: some Node {
        Label(for: "checkbox-\(name)") {
            Input(
                type: .checkbox,
                name: name,
                value: value,
                id: "checkbox-\(name)",
                required: isRequired,
                disabled: isDisabled,
                checked: isChecked
            )
            .htmlAttribute("data-part", "control")
            Text(verbatim: label)
        }
        .htmlAttribute("data-component", "checkbox")
        .htmlAttribute("data-state", isChecked ? "checked" : "unchecked")
    }
}
