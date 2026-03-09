/// A node that renders a run of text content within an HTML document.
///
/// `Text` is one of the fundamental building blocks in Score. It represents
/// inline or block-level text and renders directly as raw text content inside
/// its surrounding HTML element — it does not emit a wrapping tag of its own.
///
/// You can build a `Text` node either from a `@NodeBuilder` closure, which
/// lets you compose other inline nodes inside it, or from a plain `String`
/// using the `verbatim:` initializer for simple literal text.
///
/// ### Example — verbatim string
///
/// ```swift
/// Text { "Hello, world!" }
/// ```
///
/// ### Example — composed content
///
/// ```swift
/// Text {
///     Strong { "Important: " }
///     "Please read the terms carefully."
/// }
/// ```
///
/// - Note: `Text` has no HTML element of its own. Its children are rendered
///   directly into the parent context. To emit a `<p>` element, use
///   ``Paragraph`` instead.
public struct Text<Content: Node>: Node {

    /// The child node that provides this text node's rendered content.
    public let content: Content

    /// Creates a text node from a node-builder closure.
    ///
    /// Use this initializer when you want to compose multiple child nodes —
    /// for example, mixing ``Strong``, ``Emphasis``, or other inline nodes —
    /// inside a single text region.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Text {
    ///     Emphasis { "Note: " }
    ///     "This field is required."
    /// }
    /// ```
    ///
    /// - Parameter content: A `@NodeBuilder` closure that produces the
    ///   child node rendered inside this text node.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    /// Creates a text node from a plain string literal.
    ///
    /// This is the most direct way to insert literal text into the document.
    /// The string is wrapped in a ``TextNode`` and output verbatim — no HTML
    /// escaping beyond what the renderer applies is added.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Text { "Welcome to Score." }
    /// ```
    ///
    /// - Parameter verbatim: The raw string to render as text content.
    public init(verbatim: String) where Content == TextNode {
        self.content = TextNode(verbatim)
    }

    /// The body of this node.
    ///
    /// - Important: `Text` is a primitive node and does not have a
    ///   composable body. Accessing this property will cause a fatal error
    ///   at runtime and is reserved for the Score rendering engine.
    public var body: Never { fatalError() }
}
