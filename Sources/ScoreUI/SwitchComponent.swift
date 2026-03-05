import ScoreCore

/// A toggle switch component that acts as a styled checkbox.
///
/// `SwitchToggle` renders a checkbox input styled as a toggle switch
/// by the Score theme. It provides a boolean on/off control with an
/// accessible label.
///
/// ### Example
///
/// ```swift
/// SwitchToggle(name: "notifications", label: "Enable notifications")
/// SwitchToggle(name: "darkMode", label: "Dark mode", isOn: true)
/// ```
public struct SwitchToggle: Component {

    /// The form field name.
    public let name: String

    /// The visible label text.
    public let label: String

    /// Whether the switch is in the on position.
    public let isOn: Bool

    /// Whether the switch is disabled.
    public let isDisabled: Bool

    /// Creates a switch toggle.
    ///
    /// - Parameters:
    ///   - name: The form field name.
    ///   - label: The visible label text.
    ///   - isOn: Whether the switch is on. Defaults to `false`.
    ///   - disabled: Whether the switch is disabled. Defaults to `false`.
    public init(
        name: String,
        label: String,
        isOn: Bool = false,
        disabled: Bool = false
    ) {
        self.name = name
        self.label = label
        self.isOn = isOn
        self.isDisabled = disabled
    }

    public var body: some Node {
        Label(for: "switch-\(name)") {
            Input(
                type: .checkbox,
                name: name,
                value: "on",
                id: "switch-\(name)",
                disabled: isDisabled,
                checked: isOn
            )
            .htmlAttribute("data-part", "control")
            Text(verbatim: label)
        }
        .htmlAttribute("data-component", "switch")
        .htmlAttribute("data-state", isOn ? "checked" : "unchecked")
        .accessibility(role: "switch")
    }
}
