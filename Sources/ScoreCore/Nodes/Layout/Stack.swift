/// A generic layout container that groups child nodes into a block-level stack.
///
/// `Stack` renders as the HTML `<div>` element and is the fundamental building
/// block for composing layouts in Score. It places its children in document
/// order, stacking them vertically by default (subject to any CSS applied in
/// the rendered output).
///
/// Use `Stack` when none of the semantic containers (such as `Main`, `Section`,
/// or `Article`) accurately describes the content being grouped — for example,
/// when you need a purely presentational wrapper to apply styling.
///
/// ### Example
///
/// ```swift
/// Stack {
///     Text("Hello")
///     Text("World")
/// }
/// ```
///
/// - Note: Prefer semantic containers such as `Section` or `Article` when the
///   content has meaningful document structure, as they convey intent to both
///   browsers and assistive technologies.
public struct Stack<Content: Node>: Node, SourceLocatable {

    /// The child nodes contained within this stack.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a stack with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
