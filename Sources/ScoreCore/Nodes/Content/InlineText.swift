/// A node that renders its children with strong importance.
///
/// `Strong` wraps its children in an HTML `<strong>` element, indicating
/// that the enclosed content has strong importance, seriousness, or urgency.
/// Browsers typically render `<strong>` content in bold type, and screen
/// readers may announce it with added emphasis.
///
/// Renders as the HTML `<strong>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph {
///     Text { "Please " }
///     Strong { Text { "do not" } }
///     Text { " share your password." }
/// }
/// ```
///
/// - Note: Use `Strong` for semantic importance, not merely for visual
///   boldness. For purely decorative bold styling, prefer a CSS approach.
public struct Strong<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<strong>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a strong-importance node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Strong { Text { "Warning:" } }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Strong` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders its children with stress emphasis.
///
/// `Emphasis` wraps its children in an HTML `<em>` element, indicating
/// that the enclosed content should be spoken with emphatic stress. Browsers
/// typically render `<em>` content in italic type, and screen readers may
/// alter their intonation accordingly.
///
/// Renders as the HTML `<em>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph {
///     Text { "I " }
///     Emphasis { Text { "really" } }
///     Text { " mean it." }
/// }
/// ```
///
/// - Note: Use `Emphasis` for semantic stress, not merely for visual
///   italics. For decorative italic styling, prefer a CSS approach.
public struct Emphasis<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<em>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an emphasis node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Emphasis { Text { "Optional" } }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Emphasis` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders its children in a smaller font size.
///
/// `Small` wraps its children in an HTML `<small>` element, representing
/// side comments, fine print, or other content that is secondary to the main
/// body text — for example, copyright notices, disclaimers, or legal text.
///
/// Renders as the HTML `<small>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph {
///     Text { "Score is open source." }
/// }
/// Small {
///     Text { "© 2026 Score contributors. MIT License." }
/// }
/// ```
public struct Small<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<small>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a small node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Small { Text { "* Terms and conditions apply." } }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Small` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that highlights its children as marked or highlighted text.
///
/// `Mark` wraps its children in an HTML `<mark>` element, representing text
/// that is highlighted for reference purposes, such as a search term within
/// results or a passage of particular relevance in a longer document.
///
/// Renders as the HTML `<mark>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph {
///     Text { "Search results for " }
///     Mark { Text { "Score" } }
///     Text { ":" }
/// }
/// ```
public struct Mark<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<mark>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a mark node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Mark { Text { "highlighted term" } }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Mark` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders its children as inline computer code.
///
/// `Code` wraps its children in an HTML `<code>` element, representing a
/// fragment of computer code such as a variable name, function call, file
/// path, or any other string that would be recognised by a computer. Browsers
/// typically render `<code>` content in a monospace typeface.
///
/// Renders as the HTML `<code>` element.
///
/// ### Example
///
/// ```swift
/// Paragraph {
///     Text { "Call " }
///     Code { Text { "render()" } }
///     Text { " to produce the final HTML string." }
/// }
/// ```
///
/// - Note: For multi-line or block-level code samples, use ``Preformatted``
///   (which renders as `<pre>`) wrapping a `Code` node.
public struct Code<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<code>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a code node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Code { Text { "let page = Page { … }" } }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Code` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders its children as preformatted, whitespace-preserving text.
///
/// `Preformatted` wraps its children in an HTML `<pre>` element, preserving
/// all whitespace — including spaces, tabs, and newlines — exactly as they
/// appear in the source. Browsers render `<pre>` content in a monospace
/// typeface and do not collapse whitespace.
///
/// Renders as the HTML `<pre>` element.
///
/// ### Example — code block
///
/// ```swift
/// Preformatted {
///     Code {
///         Text { "func greet() {\n    print(\"Hello!\")\n}" }
///     }
/// }
/// ```
///
/// ### Example — ASCII art or structured text
///
/// ```swift
/// Preformatted {
///     Text { "Name    Age\n--------  ---\nAlice   30\nBob     28" }
/// }
/// ```
///
/// - Note: `Preformatted` is a block-level element. Do not nest it inside
///   other block-level elements that forbid block children (e.g., `<p>`).
public struct Preformatted<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<pre>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a preformatted node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Preformatted {
    ///     Code { Text { "let x = 42" } }
    /// }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Preformatted` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}

/// A node that renders its children as a block quotation.
///
/// `Blockquote` wraps its children in an HTML `<blockquote>` element,
/// indicating that the enclosed content is quoted from another source.
/// Browsers typically indent the content to visually set it apart from
/// the surrounding text.
///
/// Renders as the HTML `<blockquote>` element.
///
/// ### Example
///
/// ```swift
/// Blockquote {
///     Paragraph {
///         Text { "The only way to do great work is to love what you do." }
///     }
/// }
/// ```
///
/// - Note: If the source of the quotation is known, consider adding a
///   `cite` attribute via a modifier to credit the original author or work.
public struct Blockquote<Content: Node>: Node, SourceLocatable {

    /// The child node that provides the content rendered inside `<blockquote>`.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a blockquote node from a node-builder closure.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Blockquote {
    ///     Paragraph { Text { "Simplicity is the ultimate sophistication." } }
    /// }
    /// ```
    ///
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// The body of this node.
    ///
    /// - Important: `Blockquote` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}
