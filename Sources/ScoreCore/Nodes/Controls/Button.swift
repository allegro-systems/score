/// The behavioral type of a button element.
///
/// `ButtonType` maps directly to the HTML `type` attribute of the `<button>`
/// element and controls what the button does when activated inside a form
/// context.
///
/// ### Example
///
/// ```swift
/// Button(type: .submit) {
///     Text("Submit Form")
/// }
/// ```
public enum ButtonType: String, Sendable {

    /// A generic push button with no default behavior.
    ///
    /// Use `.button` for actions that are handled entirely by JavaScript or by
    /// the Score event system, such as opening a modal or toggling a menu.
    case button

    /// A button that submits the associated form's data to the server.
    ///
    /// When activated, the browser serialises the form fields and sends them to
    /// the URL specified by the form's `action` property using its `method`.
    case submit

    /// A button that resets all fields in the associated form to their initial values.
    ///
    /// Equivalent to the user manually clearing every input; use with caution,
    /// as accidental resets can be frustrating.
    case reset
}

/// A node that renders an interactive button element.
///
/// `Button` renders as the HTML `<button>` element and can contain arbitrary
/// child nodes, making it suitable for icon buttons, text-and-icon combinations,
/// or any other rich content.
///
/// The button's role within a form is determined by its `type`. When `type` is
/// `.submit`, activating the button submits the form identified by `form` (or
/// the closest ancestor `<form>` in the DOM). When `type` is `.reset`, it
/// resets that form's fields.
///
/// ### Example
///
/// ```swift
/// // A plain action button
/// Button {
///     Text("Open Menu")
/// }
///
/// // A submit button tied to a specific form by ID
/// Button(type: .submit, form: "login-form") {
///     Text("Sign In")
/// }
///
/// // A disabled reset button
/// Button(type: .reset, disabled: true) {
///     Text("Clear")
/// }
/// ```
///
/// - Note: Prefer `Button(type: .submit)` over JavaScript-driven submission
///   where possible, as it provides better browser and accessibility support.
public struct Button<Content: Node>: Node, SourceLocatable {

    /// The behavioural role of the button within a form context.
    ///
    /// Defaults to `.button` when not specified.
    public let type: ButtonType

    /// The `id` of the `<form>` element this button is associated with.
    ///
    /// When set, the button can control a form that is not its DOM ancestor.
    /// If `nil`, the button is associated with its nearest ancestor form.
    public let form: String?

    /// The name of the button, submitted as part of form data.
    ///
    /// Only relevant for `.submit` buttons. If `nil`, no name/value pair is
    /// included in the form submission.
    public let name: String?

    /// The value submitted alongside the button's `name` when the form is submitted.
    ///
    /// Only included in the form payload when this specific button triggers the
    /// submission. If `nil`, no value is sent.
    public let value: String?

    /// A Boolean value indicating whether the button is non-interactive.
    ///
    /// When `true`, the rendered `<button>` carries the `disabled` attribute,
    /// preventing user activation and excluding the button from form submission.
    public let isDisabled: Bool

    /// The child nodes that form the visible content of the button.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a button with the given configuration and child content.
    public init(
        type: ButtonType = .button,
        form: String? = nil,
        name: String? = nil,
        value: String? = nil,
        disabled: Bool = false,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.type = type
        self.form = form
        self.name = name
        self.value = value
        self.isDisabled = disabled
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
