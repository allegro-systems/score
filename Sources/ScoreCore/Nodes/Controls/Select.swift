/// A node that renders a drop-down selection control.
///
/// `Select` renders as the HTML `<select>` element, presenting the user with a
/// menu of choices built from ``Option`` and ``OptionGroup`` children. It
/// integrates with HTML forms through its `name` identifier and supports
/// single-choice as well as multi-choice modes.
///
/// Typical uses include:
/// - Choosing a country or region from a predefined list
/// - Selecting one or more categories to filter content
/// - Picking a value from a constrained set inside a form
///
/// ### Example
///
/// ```swift
/// Select(name: "country", id: "country-select", required: true) {
///     Option(value: "us") { "United States" }
///     Option(value: "ca") { "Canada" }
///     Option(value: "gb") { "United Kingdom" }
/// }
/// ```
///
/// - Important: Always pair `Select` with a visible `<label>` element whose
///   `for` attribute matches the select's `id` so that assistive technologies
///   can announce the control correctly.
public struct Select<Content: Node>: Node, SourceLocatable {

    /// The name submitted with the form data when the form is posted.
    ///
    /// If `nil`, the selected value is not included in the form submission.
    public let name: String?

    /// The unique identifier used to associate this control with a `<label>`.
    ///
    /// If `nil`, no `id` attribute is rendered.
    public let id: String?

    /// Whether the user must select a value before the form can be submitted.
    ///
    /// When `true`, renders the HTML `required` attribute.
    public let isRequired: Bool

    /// Whether the control is non-interactive and its value cannot be changed.
    ///
    /// When `true`, renders the HTML `disabled` attribute.
    public let isDisabled: Bool

    /// Whether the user can select more than one option at a time.
    ///
    /// When `true`, renders the HTML `multiple` attribute and the browser
    /// typically displays the control as a scrollable list box instead of a
    /// drop-down menu.
    public let isMultiple: Bool

    /// The child nodes that populate the control, typically ``Option`` and
    /// ``OptionGroup`` nodes.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a drop-down selection control.
    public init(
        name: String? = nil,
        id: String? = nil,
        required: Bool = false,
        disabled: Bool = false,
        multiple: Bool = false,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.name = name
        self.id = id
        self.isRequired = required
        self.isDisabled = disabled
        self.isMultiple = multiple
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A single selectable choice inside a ``Select`` control.
///
/// `Option` renders as the HTML `<option>` element. Each instance represents
/// one item the user can choose. Its `content` is displayed as the visible
/// label, while `value` is the data submitted to the server.
///
/// ### Example
///
/// ```swift
/// Select(name: "size") {
///     Option(value: "s") { "Small" }
///     Option(value: "m", selected: true) { "Medium" }
///     Option(value: "l") { "Large" }
/// }
/// ```
public struct Option<Content: Node>: Node, SourceLocatable {

    /// The value submitted with the form when this option is selected.
    ///
    /// If `nil`, the text content of the option is used as the submitted value.
    public let value: String?

    /// Whether this option is pre-selected when the page loads.
    ///
    /// When `true`, renders the HTML `selected` attribute.
    public let isSelected: Bool

    /// Whether this option is non-interactive and cannot be chosen.
    ///
    /// When `true`, renders the HTML `disabled` attribute and the browser
    /// typically grays out the option.
    public let isDisabled: Bool

    /// The visible label content rendered inside the option element.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a selectable option.
    public init(
        value: String? = nil,
        selected: Bool = false,
        disabled: Bool = false,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.value = value
        self.isSelected = selected
        self.isDisabled = disabled
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A labeled group of related options inside a ``Select`` control.
///
/// `OptionGroup` renders as the HTML `<optgroup>` element. Use it to visually
/// and semantically cluster ``Option`` items under a shared heading, which
/// improves scannability when a select list contains many choices.
///
/// ### Example
///
/// ```swift
/// Select(name: "car") {
///     OptionGroup(label: "Swedish Cars") {
///         Option(value: "volvo") { "Volvo" }
///         Option(value: "saab") { "Saab" }
///     }
///     OptionGroup(label: "German Cars") {
///         Option(value: "mercedes") { "Mercedes" }
///         Option(value: "audi") { "Audi" }
///     }
/// }
/// ```
///
/// - Important: `OptionGroup` labels are not submitted as form values; they
///   exist solely to annotate the visual grouping for the user.
public struct OptionGroup<Content: Node>: Node, SourceLocatable {

    /// The visible heading text displayed above the grouped options.
    ///
    /// Rendered as the `label` attribute on the HTML `<optgroup>` element.
    public let label: String

    /// Whether all options within this group are non-interactive.
    ///
    /// When `true`, renders the HTML `disabled` attribute on the group element,
    /// which disables every contained ``Option`` simultaneously.
    public let isDisabled: Bool

    /// The ``Option`` nodes that belong to this group.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a labeled group of options.
    public init(
        label: String,
        disabled: Bool = false,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.label = label
        self.isDisabled = disabled
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}
