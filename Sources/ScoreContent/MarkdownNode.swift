import ScoreCore

/// A composite node that parses a Markdown string and renders it as a Score
/// node tree.
///
/// `MarkdownNode` is the primary entry point for embedding Markdown content
/// in a Score document. It accepts a raw Markdown string, converts it using
/// ``MarkdownConverter``, and renders the resulting blocks as Score nodes.
///
/// ```swift
/// MarkdownNode("# Hello\n\nWelcome to **Score**.")
/// ```
public struct MarkdownNode: Node {

    /// The converted block-level elements from the Markdown source.
    public let blocks: [MarkdownBlock]

    /// Creates a Markdown node by parsing the given string.
    ///
    /// - Parameters:
    ///   - markdown: A Markdown-formatted string to parse and render.
    ///   - theme: The syntax theme for code blocks. Defaults to
    ///     ``SyntaxTheme/scoreDefault``.
    public init(_ markdown: String, theme: SyntaxTheme = .scoreDefault) {
        let converter = MarkdownConverter(theme: theme)
        self.blocks = converter.convert(markdown)
    }

    /// Creates a Markdown node from pre-converted blocks.
    ///
    /// - Parameter blocks: An array of ``MarkdownBlock`` values.
    public init(blocks: [MarkdownBlock]) {
        self.blocks = blocks
    }

    public var body: some Node {
        Stack {
            ForEachNode(IndexedCollection(blocks)) { indexed in
                BlockNodeView(block: indexed.element)
            }
        }
    }
}

/// Renders a single ``MarkdownBlock`` as a Score node.
struct BlockNodeView: Node {

    let block: MarkdownBlock

    var body: some Node {
        switch block {
        case .heading(let level, let children):
            Heading(level) {
                InlineNodesView(inlines: children)
            }
        case .paragraph(let children):
            Paragraph {
                InlineNodesView(inlines: children)
            }
        case .codeBlock(let code, let language, let theme):
            CodeBlock(code: code, language: language, theme: theme)
        case .math(let latex):
            MathExpression(latex)
        case .blockquote(let children):
            Blockquote {
                ForEachNode(IndexedCollection(children)) { indexed in
                    BlockNodeView(block: indexed.element)
                }
            }
        case .unorderedList(let items):
            UnorderedList {
                ForEachNode(IndexedCollection(items)) { indexed in
                    ListItem {
                        ForEachNode(IndexedCollection(indexed.element)) { inner in
                            BlockNodeView(block: inner.element)
                        }
                    }
                }
            }
        case .orderedList(let items):
            OrderedList {
                ForEachNode(IndexedCollection(items)) { indexed in
                    ListItem {
                        ForEachNode(IndexedCollection(indexed.element)) { inner in
                            BlockNodeView(block: inner.element)
                        }
                    }
                }
            }
        case .thematicBreak:
            HorizontalRule()
        case .rawHTML(let html):
            Text { html }
        case .table(let headers, let rows):
            Table {
                TableHead {
                    TableRow {
                        ForEachNode(IndexedCollection(headers)) { indexed in
                            TableHeaderCell {
                                InlineNodesView(inlines: indexed.element)
                            }
                        }
                    }
                }
                TableBody {
                    ForEachNode(IndexedCollection(rows)) { indexed in
                        TableRow {
                            ForEachNode(IndexedCollection(indexed.element)) { inner in
                                TableCell {
                                    InlineNodesView(inlines: inner.element)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Renders a sequence of ``MarkdownInline`` values as Score inline nodes.
struct InlineNodesView: Node {

    let inlines: [MarkdownInline]

    var body: some Node {
        ForEachNode(IndexedCollection(inlines)) { indexed in
            InlineNodeView(inline: indexed.element)
        }
    }
}

/// Renders a single ``MarkdownInline`` as a Score inline node.
struct InlineNodeView: Node {

    let inline: MarkdownInline

    var body: some Node {
        switch inline {
        case .text(let string):
            Text { string }
        case .emphasis(let children):
            Emphasis {
                InlineNodesView(inlines: children)
            }
        case .strong(let children):
            Strong {
                InlineNodesView(inlines: children)
            }
        case .code(let code):
            Code { code }
        case .link(let destination, let children):
            Link(to: destination) {
                InlineNodesView(inlines: children)
            }
        case .image(let src, let alt):
            Image(src: src, alt: alt)
        case .lineBreak:
            LineBreak()
        case .rawInlineHTML(let html):
            Text { html }
        }
    }
}

/// A `RandomAccessCollection` wrapper that pairs each element with its index,
/// making arrays of non-`Identifiable` enums usable with `ForEachNode`.
struct IndexedCollection<Element: Sendable>: RandomAccessCollection, Sendable {

    /// An element paired with its integer index for stable identity.
    struct IndexedElement: Sendable {
        let index: Int
        let element: Element
    }

    private let elements: [Element]

    init(_ elements: [Element]) {
        self.elements = elements
    }

    var startIndex: Int { 0 }
    var endIndex: Int { elements.count }

    subscript(position: Int) -> IndexedElement {
        IndexedElement(index: position, element: elements[position])
    }
}
