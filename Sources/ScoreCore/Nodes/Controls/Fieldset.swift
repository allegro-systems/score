/// A node that groups related form controls under a common border and legend.
///
/// `Fieldset` renders as the HTML `<fieldset>` element. It draws a visual
/// border around a set of related inputs and, when combined with a ``Legend``
/// child, provides an accessible caption for that group. Disabling a
/// `Fieldset` simultaneously disables all of its descendant controls.
///
/// Typical uses include:
/// - Grouping personal-information fields (name, email, phone) in a
///   registration form
/// - Wrapping a set of radio buttons that represent mutually exclusive choices
/// - Sectioning a long form into logical, captioned regions
///
/// ### Example
///
/// ```swift
/// Fieldset {
///     Legend { "Shipping Address" }
///     Input(type: .text, name: "street", placeholder: "Street")
///     Input(type: .text, name: "city", placeholder: "City")
///     Input(type: .text, name: "zip", placeholder: "ZIP")
/// }
/// ```
///
/// - Important: Placing a ``Legend`` as the first child of a `Fieldset` is
///   strongly recommended; it is the primary mechanism by which assistive
///   technologies identify the purpose of the group.
public struct Fieldset<Content: Node>: Node, SourceLocatable {

    /// Whether all descendant form controls within this fieldset are disabled.
    ///
    /// When `true`, renders the HTML `disabled` attribute on the `<fieldset>`
    /// element, which propagates the disabled state to every contained control
    /// and excludes their values from form submission.
    public let isDisabled: Bool

    /// The child nodes that make up the fieldset, typically a ``Legend``
    /// followed by one or more form controls.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a fieldset that groups related form controls.
    public init(
        disabled: Bool = false,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.isDisabled = disabled
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that provides a visible caption for a ``Fieldset``.
///
/// `Legend` renders as the HTML `<legend>` element. It must be the first child
/// of a ``Fieldset`` to be correctly associated with the group by browsers and
/// assistive technologies.
///
/// ### Example
///
/// ```swift
/// Fieldset {
///     Legend { "Payment Details" }
///     Input(type: .text, name: "card-number", placeholder: "Card number")
///     Input(type: .text, name: "expiry", placeholder: "MM/YY")
/// }
/// ```
public struct Legend<Content: Node>: Node, SourceLocatable {

    /// The caption content displayed as the fieldset's title.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a legend caption for a ``Fieldset``.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that displays the result of a calculation or user action.
///
/// `Output` renders as the HTML `<output>` element. It is a semantic container
/// for computed or dynamic values — for example, the running total of a
/// shopping cart, a live character count, or the result of a form-based
/// calculator. Linking it to a source control via `forID` communicates the
/// relationship to assistive technologies.
///
/// ### Example
///
/// ```swift
/// Input(type: .range, name: "volume", id: "volume-slider")
/// Output(for: "volume-slider") { "50" }
/// ```
///
/// - Important: `Output` is not a form-submission field. Its content is
///   presented to the user but is not sent with the form data.
public struct Output<Content: Node>: Node, SourceLocatable {

    /// The `id` of the form control whose value this output represents.
    ///
    /// Rendered as the HTML `for` attribute. If `nil`, no explicit association
    /// is declared.
    public let forID: String?

    /// The content displayed as the computed result.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates an output element associated with a form control.
    public init(
        for forID: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.forID = forID
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}
