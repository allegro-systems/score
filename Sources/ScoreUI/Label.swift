import ScoreCore

/// A styled label component for form controls.
///
/// `FormLabel` wraps the core ``Label`` node with additional
/// styling hooks for the Score theme. Use it to annotate form
/// fields with accessible, visible captions.
///
/// ### Example
///
/// ```swift
/// FormLabel(for: "email-input") {
///     Text(verbatim: "Email Address")
/// }
/// ```
public struct FormLabel<Content: Node>: Component {

    /// The `id` of the form control this label is associated with.
    public let forID: String?

    /// Whether the associated field is required.
    public let isRequired: Bool

    /// The label content.
    public let content: Content

    /// Creates a form label.
    ///
    /// - Parameters:
    ///   - forID: The `id` of the associated control. Defaults to `nil`.
    ///   - required: Whether the field is required. Defaults to `false`.
    ///   - content: A `@NodeBuilder` closure producing the label text.
    public init(
        for forID: String? = nil,
        required: Bool = false,
        @NodeBuilder content: () -> Content
    ) {
        self.forID = forID
        self.isRequired = required
        self.content = content()
    }

    public var body: some Node {
        Label(for: forID) {
            content
        }
        .htmlAttribute("data-component", "label")
    }
}
