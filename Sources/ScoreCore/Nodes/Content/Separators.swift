/// A node that renders a thematic break between content sections.
///
/// `HorizontalRule` emits an HTML `<hr>` element, which represents a
/// thematic break at the paragraph level — for example, a scene change
/// in a story, a transition between topics, or a visual divider between
/// major sections of content. Browsers typically render it as a horizontal
/// line spanning the width of its container.
///
/// Renders as the HTML `<hr>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph { Text(verbatim: "End of section one.") }
/// HorizontalRule()
/// Paragraph { Text(verbatim: "Beginning of section two.") }
/// ```
///
/// - Note: `HorizontalRule` is a void element and has no children. Its
///   visual appearance can be controlled entirely through CSS.
public struct HorizontalRule: Node, SourceLocatable {

    public let sourceLocation: SourceLocation

    /// Creates a horizontal rule node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// HorizontalRule()
    /// ```
    public init(file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// The body of this node.
    ///
    /// - Important: `HorizontalRule` is a primitive node and does not have
    ///   a composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders a line break within inline content.
///
/// `LineBreak` emits an HTML `<br>` element, forcing a line break at the
/// point where it appears without starting a new paragraph. It is appropriate
/// for content where the line division is semantically significant — such as
/// lines in a postal address, verses in a poem, or multi-line captions.
///
/// Renders as the HTML `<br>` element.
///
/// ### Example — address formatting
///
/// ```swift
/// Address {
///     Text(verbatim: "123 Main Street")
///     LineBreak()
///     Text(verbatim: "Springfield, IL 62701")
/// }
/// ```
///
/// ### Example — poem or verse
///
/// ```swift
/// Paragraph {
///     Text(verbatim: "Roses are red,")
///     LineBreak()
///     Text(verbatim: "Violets are blue.")
/// }
/// ```
///
/// - Important: Do not use `LineBreak` to add vertical spacing between
///   paragraphs or sections. Use separate ``Paragraph`` nodes or CSS margin
///   instead. `LineBreak` is only appropriate where the line ending itself
///   carries meaning.
public struct LineBreak: Node, SourceLocatable {

    public let sourceLocation: SourceLocation

    /// Creates a line break node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// LineBreak()
    /// ```
    public init(file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    /// The body of this node.
    ///
    /// - Important: `LineBreak` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}
