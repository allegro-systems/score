/// A node that groups self-contained media content with an optional caption.
///
/// `Figure` renders as the HTML `<figure>` element. It is intended to wrap
/// content that is referenced from the main document flow but could be moved
/// to a different position without affecting that flow — such as images,
/// illustrations, diagrams, code listings, or tables.
///
/// Pair `Figure` with `FigureCaption` to provide a visible caption that is
/// semantically associated with the grouped content.
///
/// ### Example
///
/// ```swift
/// Figure {
///     Image(src: "/images/architecture.png", alt: "System architecture diagram")
///     FigureCaption {
///         Text("Figure 1 — High-level system architecture.")
///     }
/// }
/// ```
public struct Figure<Content: Node>: Node, SourceLocatable {

    /// The child node or node tree nested inside the figure element.
    ///
    /// Typically contains an `Image`, `Picture`, `Video`, or similar media
    /// node, optionally followed by a `FigureCaption`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a figure node containing the given content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `Figure` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `Figure` directly.
    public var body: Never { fatalError() }
}

/// A node that provides a visible caption for a `Figure`.
///
/// `FigureCaption` renders as the HTML `<figcaption>` element. It must be placed
/// as a direct child of a `Figure` node, either as its first or last child.
/// The browser and assistive technologies use this element to associate the
/// caption text with the surrounding figure.
///
/// ### Example
///
/// ```swift
/// Figure {
///     Image(src: "/photos/team.jpg", alt: "The engineering team")
///     FigureCaption {
///         Text("The core engineering team at our 2025 offsite.")
///     }
/// }
/// ```
public struct FigureCaption<Content: Node>: Node, SourceLocatable {

    /// The child node or node tree that forms the caption text and inline
    /// content.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a figure caption node containing the given content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// `FigureCaption` is a primitive node and does not compose a `body`.
    ///
    /// - Important: Accessing this property at runtime will terminate
    ///   execution. The renderer handles `FigureCaption` directly.
    public var body: Never { fatalError() }
}
