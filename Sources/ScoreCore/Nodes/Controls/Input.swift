/// The data type and widget style of an input control.
///
/// `InputType` maps directly to the `type` attribute of the HTML `<input>`
/// element and governs both the kind of data the field accepts and the
/// native browser widget used to collect it.
///
/// ### Example
///
/// ```swift
/// Input(type: .email, name: "userEmail", placeholder: "you@example.com")
/// Input(type: .date, name: "birthday")
/// Input(type: .checkbox, name: "acceptTerms")
/// ```
public enum InputType: String, Sendable {

    /// A single-line plain-text field.
    ///
    /// Accepts any character sequence. The most general-purpose input type.
    case text

    /// A field for email addresses.
    ///
    /// Browsers validate the value's format and may present an optimised
    /// keyboard on mobile devices (e.g. showing `@` prominently).
    case email

    /// A field whose value is obscured from view.
    ///
    /// Characters are masked so that bystanders cannot read the value.
    /// Use for passwords and other secrets.
    case password

    /// A field for numeric values.
    ///
    /// Browsers may render increment/decrement spinners and restrict input to
    /// digits, decimal separators, and sign characters.
    case number

    /// A field whose value is not displayed or editable by the user.
    ///
    /// Use to include data in a form submission that the user should not see
    /// or modify, such as CSRF tokens or record identifiers.
    case hidden

    /// A single-line text field styled and semantically marked as a search box.
    ///
    /// Functionally similar to `.text`, but browsers may add a clear button
    /// and search-specific styling.
    case search

    /// A field for telephone numbers.
    ///
    /// No format validation is enforced, but mobile browsers typically present
    /// a numeric/phone keypad layout.
    case tel

    /// A field for absolute URLs.
    ///
    /// Browsers validate that the value is a well-formed URL and may show a
    /// URL-optimised keyboard on mobile devices.
    case url

    /// A date picker limited to year, month, and day.
    ///
    /// The submitted value is formatted as `YYYY-MM-DD`.
    case date

    /// A time picker limited to hours and minutes (and optionally seconds).
    ///
    /// The submitted value is formatted as `HH:MM` or `HH:MM:SS`.
    case time

    /// A file-upload control that opens the system's file picker.
    ///
    /// Requires the enclosing `Form` to use `.multipart` encoding.
    case file

    /// A boolean on/off toggle rendered as a checkbox.
    ///
    /// The field's `value` is submitted only when the checkbox is checked.
    case checkbox

    /// A single-selection control within a group of options sharing the same `name`.
    ///
    /// Only the selected radio button in a group contributes its `value` to
    /// the form submission.
    case radio

    /// A slider control for selecting a numeric value within a range.
    ///
    /// The exact value is not typically displayed to the user. Combine with an
    /// output element if the current value needs to be visible.
    case range

    /// A colour picker that returns a hex colour string (e.g. `#ff0000`).
    case color

    /// A date picker limited to year and month.
    ///
    /// The submitted value is formatted as `YYYY-MM`.
    case month

    /// A date picker limited to year and ISO week number.
    ///
    /// The submitted value is formatted as `YYYY-Www`.
    case week

    /// A combined date and time picker in the user's local time zone.
    ///
    /// The submitted value is formatted as `YYYY-MM-DDTHH:MM`.
    case datetimeLocal = "datetime-local"
}

/// A node that renders a single-field form control.
///
/// `Input` renders as the HTML `<input>` element — a self-closing, void element
/// with no children. The control's visual appearance and accepted data are
/// determined by the `type` property.
///
/// Pair an `Input` with a `Label` that references the input's `id` to satisfy
/// accessibility requirements, ensuring screen readers can announce the field's
/// purpose.
///
/// ### Example
///
/// ```swift
/// // A required email field with a placeholder
/// Input(type: .email, name: "email", placeholder: "you@example.com",
///       id: "email-field", required: true)
///
/// // A pre-populated, read-only text field
/// Input(type: .text, name: "username", value: "jdoe", readOnly: true)
///
/// // A hidden field carrying a CSRF token
/// Input(type: .hidden, name: "csrf_token", value: token)
/// ```
///
/// - Important: Always associate visible inputs with a `Label` via the
///   input's `id` to meet accessibility standards.
public struct Input: Node, SourceLocatable {

    /// The data type and widget style of this input control.
    ///
    /// Corresponds to the `type` attribute on the HTML `<input>` element.
    public let type: InputType

    /// The name key submitted with this field's value in form data.
    ///
    /// If `nil`, the input is not included in the form submission. Corresponds
    /// to the `name` attribute on the HTML `<input>` element.
    public let name: String?

    /// Short hint text displayed inside the control when it has no value.
    ///
    /// Disappears as soon as the user begins typing. Do not use placeholder
    /// text as a substitute for a visible `Label`. Corresponds to the
    /// `placeholder` attribute on the HTML `<input>` element.
    public let placeholder: String?

    /// The pre-filled or programmatically set value of the control.
    ///
    /// For most input types this is the initial displayed value. For
    /// `.checkbox` and `.radio`, it is the value sent when the control is
    /// selected. Corresponds to the `value` attribute on the HTML `<input>`
    /// element.
    public let value: String?

    /// A unique identifier for this input element.
    ///
    /// Used by `Label(for:)` to associate a visible label with the control,
    /// which is critical for accessibility. Corresponds to the `id` attribute
    /// on the HTML `<input>` element.
    public let id: String?

    /// A Boolean value indicating whether the user must fill in this field before submitting the form.
    ///
    /// When `true`, the rendered `<input>` carries the `required` attribute
    /// and the browser prevents submission if the field is empty.
    public let isRequired: Bool

    /// A Boolean value indicating whether the field is non-interactive.
    ///
    /// When `true`, the rendered `<input>` carries the `disabled` attribute,
    /// preventing the user from editing the value or including it in a form
    /// submission.
    public let isDisabled: Bool

    /// A Boolean value indicating whether the field's value may be read but not changed.
    ///
    /// When `true`, the rendered `<input>` carries the `readonly` attribute.
    /// Unlike a disabled input, a read-only input is still focusable and
    /// its value is included in the form submission.
    public let isReadOnly: Bool

    /// A Boolean value indicating whether a checkbox or radio input is initially selected.
    ///
    /// When `true`, the rendered `<input>` carries the `checked` attribute.
    /// Only meaningful for `.checkbox` and `.radio` input types.
    public let isChecked: Bool

    /// The minimum acceptable value for range, number, date, and time inputs.
    ///
    /// Corresponds to the `min` attribute on the HTML `<input>` element.
    public let min: String?

    /// The maximum acceptable value for range, number, date, and time inputs.
    ///
    /// Corresponds to the `max` attribute on the HTML `<input>` element.
    public let max: String?

    /// The identifier of a `DataList` providing suggested values.
    ///
    /// Corresponds to the `list` attribute on the HTML `<input>` element.
    public let list: String?

    public let sourceLocation: SourceLocation

    /// Creates an input control with the given configuration.
    public init(
        type: InputType,
        name: String? = nil,
        placeholder: String? = nil,
        value: String? = nil,
        id: String? = nil,
        required: Bool = false,
        disabled: Bool = false,
        readOnly: Bool = false,
        checked: Bool = false,
        min: String? = nil,
        max: String? = nil,
        list: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.type = type
        self.name = name
        self.placeholder = placeholder
        self.value = value
        self.id = id
        self.isRequired = required
        self.isDisabled = disabled
        self.isReadOnly = readOnly
        self.isChecked = checked
        self.min = min
        self.max = max
        self.list = list
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
