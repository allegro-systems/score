/// A node that provides a list of suggested values for an associated text input.
///
/// `DataList` renders as the HTML `<datalist>` element. It supplies an
/// autocomplete dropdown of predefined suggestions that appear as the user
/// types into a text ``Input`` whose `list` attribute matches this element's
/// `id`. Unlike a ``Select``, the user is not restricted to the listed values
/// and may still type any freeform text.
///
/// Typical uses include:
/// - Suggesting common search terms in a search field
/// - Offering pre-populated city names while still allowing custom entries
/// - Providing airport codes or currency symbols as autocomplete hints
///
/// ### Example
///
/// ```swift
/// Input(type: .text, name: "browser", list: "browsers-list")
/// DataList(id: "browsers-list") {
///     Option(value: "Chrome") { "" }
///     Option(value: "Firefox") { "" }
///     Option(value: "Safari") { "" }
///     Option(value: "Edge") { "" }
/// }
/// ```
///
/// - Important: The `id` of the `DataList` must match the `list` attribute of
///   the associated input for the browser to display the suggestions.
public struct DataList<Content: Node>: Node, SourceLocatable {

    /// The unique identifier that links this datalist to an input's `list`
    /// attribute.
    ///
    /// If `nil`, no `id` attribute is rendered and the datalist cannot be
    /// associated with any input via the standard HTML mechanism.
    public let id: String?

    /// The ``Option`` nodes that define the autocomplete suggestions.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a datalist of autocomplete suggestions.
    public init(
        id: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.id = id
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    public var body: Never { fatalError() }
}
