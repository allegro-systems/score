/// A node that renders a caption associated with a form control.
///
/// `Label` renders as the HTML `<label>` element. When its `forID` property is
/// set to the `id` of an `Input` or other labelable control, the browser
/// creates a programmatic association between the two elements. This allows
/// users to activate the control by clicking the label text, and enables screen
/// readers to announce the label's content when the associated control receives
/// focus.
///
/// A `Label` can also implicitly wrap its associated control as a child node
/// instead of using `forID`, but the explicit `forID` approach is generally
/// preferred for layout flexibility.
///
/// ### Example
///
/// ```swift
/// // Explicit association via matching IDs
/// Label(for: "username-input") {
///     Text("Username")
/// }
/// Input(type: .text, name: "username", id: "username-input")
///
/// // Label without an association — useful for group captions
/// Label {
///     Text("Preferred contact method")
/// }
/// ```
///
/// - Important: Every visible `Input` should have an associated `Label`.
///   Omitting labels is a common accessibility failure that prevents screen
///   reader users from understanding the purpose of a form field.
public struct Label<Content: Node>: Node, SourceLocatable {

    /// The `id` of the form control this label is associated with.
    ///
    /// When set, clicking the label moves focus to — or activates — the
    /// corresponding control. Corresponds to the `for` attribute on the HTML
    /// `<label>` element. If `nil`, no explicit association is established.
    public let forID: String?

    /// The child nodes that form the visible caption of the label.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a label with an optional control association and the given child content.
    public init(
        for forID: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.forID = forID
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
