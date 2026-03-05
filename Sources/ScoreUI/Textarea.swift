import ScoreCore

/// A labeled multi-line text input field.
///
/// `TextareaField` combines a ``Label`` with a ``TextArea`` control,
/// providing an accessible multi-line text input with optional helper
/// and error text.
///
/// ### Example
///
/// ```swift
/// TextareaField(
///     label: "Message",
///     name: "message",
///     placeholder: "Write your message...",
///     rows: 6
/// )
/// ```
public struct TextareaField: Component {

    /// The visible label text.
    public let label: String

    /// The form field name.
    public let name: String

    /// Placeholder text shown when the field is empty.
    public let placeholder: String?

    /// The initial value of the field.
    public let value: String?

    /// The visible number of text lines.
    public let rows: Int?

    /// Whether the field is required.
    public let isRequired: Bool

    /// Whether the field is disabled.
    public let isDisabled: Bool

    /// Optional helper text displayed below the textarea.
    public let helperText: String?

    /// Optional error message displayed below the textarea.
    public let errorText: String?

    /// Creates a labeled textarea field.
    ///
    /// - Parameters:
    ///   - label: The visible label text.
    ///   - name: The form field name.
    ///   - placeholder: Hint text. Defaults to `nil`.
    ///   - value: The initial value. Defaults to `nil`.
    ///   - rows: Visible text lines. Defaults to `nil`.
    ///   - required: Whether the field is required. Defaults to `false`.
    ///   - disabled: Whether the field is disabled. Defaults to `false`.
    ///   - helperText: Optional helper text. Defaults to `nil`.
    ///   - errorText: Optional error text. Defaults to `nil`.
    public init(
        label: String,
        name: String,
        placeholder: String? = nil,
        value: String? = nil,
        rows: Int? = nil,
        required: Bool = false,
        disabled: Bool = false,
        helperText: String? = nil,
        errorText: String? = nil
    ) {
        self.label = label
        self.name = name
        self.placeholder = placeholder
        self.value = value
        self.rows = rows
        self.isRequired = required
        self.isDisabled = disabled
        self.helperText = helperText
        self.errorText = errorText
    }

    public var body: some Node {
        Stack {
            Label(for: "textarea-\(name)") {
                Text(verbatim: label)
            }
            .htmlAttribute("data-part", "label")
            TextArea(
                name: name,
                placeholder: placeholder,
                value: value,
                rows: rows,
                id: "textarea-\(name)",
                required: isRequired,
                disabled: isDisabled
            )
            .htmlAttribute("data-part", "textarea")
            if let errorText {
                Paragraph { Text(verbatim: errorText) }
                    .htmlAttribute("data-part", "error")
            } else if let helperText {
                Paragraph { Text(verbatim: helperText) }
                    .htmlAttribute("data-part", "helper")
            }
        }
        .htmlAttribute("data-component", "textarea")
        .htmlAttribute("data-state", errorText != nil ? "error" : "default")
    }
}
