import ScoreCore

/// A labeled text input field combining a ``Label`` and an ``Input``.
///
/// `InputField` provides a convenience wrapper that pairs label text
/// with an input control and optional helper or error text.
///
/// ### Example
///
/// ```swift
/// InputField(
///     label: "Email",
///     name: "email",
///     type: .email,
///     placeholder: "you@example.com",
///     required: true
/// )
/// ```
public struct InputField: Component {

    /// The visible label text for the input.
    public let label: String

    /// The form field name.
    public let name: String

    /// The input control type.
    public let type: InputType

    /// Placeholder text shown when the field is empty.
    public let placeholder: String?

    /// The initial value of the field.
    public let value: String?

    /// Whether the field is required for form submission.
    public let isRequired: Bool

    /// Whether the field is non-interactive.
    public let isDisabled: Bool

    /// Optional helper text displayed below the input.
    public let helperText: String?

    /// Optional error message displayed below the input.
    public let errorText: String?

    /// Creates a labeled input field.
    ///
    /// - Parameters:
    ///   - label: The visible label text.
    ///   - name: The form field name.
    ///   - type: The input type. Defaults to `.text`.
    ///   - placeholder: Hint text for an empty field. Defaults to `nil`.
    ///   - value: The initial value. Defaults to `nil`.
    ///   - required: Whether the field is required. Defaults to `false`.
    ///   - disabled: Whether the field is disabled. Defaults to `false`.
    ///   - helperText: Optional helper text. Defaults to `nil`.
    ///   - errorText: Optional error text. Defaults to `nil`.
    public init(
        label: String,
        name: String,
        type: InputType = .text,
        placeholder: String? = nil,
        value: String? = nil,
        required: Bool = false,
        disabled: Bool = false,
        helperText: String? = nil,
        errorText: String? = nil
    ) {
        self.label = label
        self.name = name
        self.type = type
        self.placeholder = placeholder
        self.value = value
        self.isRequired = required
        self.isDisabled = disabled
        self.helperText = helperText
        self.errorText = errorText
    }

    public var body: some Node {
        Stack {
            Label(for: "input-\(name)") {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "label")
            Input(
                type: type,
                name: name,
                placeholder: placeholder,
                value: value,
                id: "input-\(name)",
                required: isRequired,
                disabled: isDisabled
            )
            .htmlAttribute("data-part", "input")
            if let errorText {
                Paragraph { Text(verbatim: errorText) }
                    .htmlAttribute("data-part", "error")
            } else if let helperText {
                Paragraph { Text(verbatim: helperText) }
                    .htmlAttribute("data-part", "helper")
            }
        }
        .htmlAttribute("data-component", "input")
        .htmlAttribute("data-state", errorText != nil ? "error" : "default")
    }
}
