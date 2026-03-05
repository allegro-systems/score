import Markdown
import ScoreCore

/// Converts a swift-markdown `Document` into a Score `Node` tree.
///
/// `MarkdownConverter` implements `MarkupWalker` from the swift-markdown
/// package to traverse a parsed Markdown AST and produce an equivalent
/// tree of Score nodes. The converter handles headings, paragraphs, links,
/// images, emphasis, strong, code spans, fenced code blocks (with optional
/// math block support), blockquotes, lists, thematic breaks, and tables.
///
/// Fenced code blocks with the `math` info string are rendered as
/// ``MathExpression`` nodes instead of ``CodeBlock`` nodes.
///
/// ```swift
/// let document = Document(parsing: markdownString)
/// let converter = MarkdownConverter(theme: .scoreDefault)
/// let nodes = converter.convert(document)
/// ```
public struct MarkdownConverter: Sendable {

    /// The syntax theme applied to fenced code blocks.
    public let theme: SyntaxTheme

    /// Creates a converter with the given syntax theme.
    ///
    /// - Parameter theme: The ``SyntaxTheme`` for code blocks. Defaults to
    ///   ``SyntaxTheme/scoreDefault``.
    public init(theme: SyntaxTheme = .scoreDefault) {
        self.theme = theme
    }

    /// Converts a swift-markdown `Document` into an array of Score node
    /// wrappers.
    ///
    /// Each top-level block element in the document becomes one ``MarkdownBlock``
    /// entry in the returned array. Callers can iterate the array or embed it
    /// directly in a `@NodeBuilder` block via ``MarkdownNode``.
    ///
    /// - Parameter document: A parsed swift-markdown `Document`.
    /// - Returns: An array of ``MarkdownBlock`` values representing the
    ///   document's block-level content.
    public func convert(_ document: Document) -> [MarkdownBlock] {
        document.children.flatMap { convertBlock($0) }
    }

    /// Converts a raw Markdown string into an array of Score node wrappers.
    ///
    /// This is a convenience that parses the string and converts in one step.
    ///
    /// - Parameter markdown: A Markdown-formatted string.
    /// - Returns: An array of ``MarkdownBlock`` values.
    public func convert(_ markdown: String) -> [MarkdownBlock] {
        let document = Document(parsing: markdown)
        return convert(document)
    }
}

extension MarkdownConverter {

    func convertBlock(_ markup: any Markup) -> [MarkdownBlock] {
        switch markup {
        case let heading as Markdown.Heading:
            let level = headingLevel(heading.level)
            let inlines = convertInlines(heading.children)
            return [.heading(level: level, children: inlines)]

        case let paragraph as Markdown.Paragraph:
            let inlines = convertInlines(paragraph.children)
            return [.paragraph(children: inlines)]

        case let codeBlock as Markdown.CodeBlock:
            let language = codeBlock.language
            let code = codeBlock.code
            if language == "math" {
                return [.math(latex: code.trimmingCharacters(in: .whitespacesAndNewlines))]
            }
            return [.codeBlock(code: code, language: language, theme: theme)]

        case let blockquote as Markdown.BlockQuote:
            let children = blockquote.children.flatMap { convertBlock($0) }
            return [.blockquote(children: children)]

        case let unorderedList as Markdown.UnorderedList:
            let items = unorderedList.children.compactMap { child -> [MarkdownBlock]? in
                guard let item = child as? Markdown.ListItem else { return nil }
                return item.children.flatMap { convertBlock($0) }
            }
            return [.unorderedList(items: items)]

        case let orderedList as Markdown.OrderedList:
            let items = orderedList.children.compactMap { child -> [MarkdownBlock]? in
                guard let item = child as? Markdown.ListItem else { return nil }
                return item.children.flatMap { convertBlock($0) }
            }
            return [.orderedList(items: items)]

        case is Markdown.ThematicBreak:
            return [.thematicBreak]

        case let htmlBlock as Markdown.HTMLBlock:
            return [.rawHTML(htmlBlock.rawHTML)]

        case let table as Markdown.Table:
            return convertTable(table)

        default:
            return []
        }
    }

    func convertInlines(_ children: some Sequence<any Markup>) -> [MarkdownInline] {
        children.flatMap { convertInline($0) }
    }

    func convertInline(_ markup: any Markup) -> [MarkdownInline] {
        switch markup {
        case let text as Markdown.Text:
            return [.text(text.string)]

        case let emphasis as Markdown.Emphasis:
            let children = convertInlines(emphasis.children)
            return [.emphasis(children: children)]

        case let strong as Markdown.Strong:
            let children = convertInlines(strong.children)
            return [.strong(children: children)]

        case let code as Markdown.InlineCode:
            return [.code(code.code)]

        case let link as Markdown.Link:
            let children = convertInlines(link.children)
            return [.link(destination: link.destination ?? "", children: children)]

        case let image as Markdown.Image:
            return [.image(src: image.source ?? "", alt: image.plainText)]

        case is Markdown.SoftBreak:
            return [.text(" ")]

        case is Markdown.LineBreak:
            return [.lineBreak]

        case let html as Markdown.InlineHTML:
            return [.rawInlineHTML(html.rawHTML)]

        default:
            return []
        }
    }

    func convertTable(_ table: Markdown.Table) -> [MarkdownBlock] {
        var headerRows: [[MarkdownInline]] = []
        for cell in table.head.cells {
            headerRows.append(convertInlines(cell.children))
        }

        var bodyRows: [[[MarkdownInline]]] = []
        for row in table.body.rows {
            var rowCells: [[MarkdownInline]] = []
            for cell in row.cells {
                rowCells.append(convertInlines(cell.children))
            }
            bodyRows.append(rowCells)
        }

        return [.table(headers: headerRows, rows: bodyRows)]
    }

    func headingLevel(_ level: Int) -> HeadingLevel {
        switch level {
        case 1: return .one
        case 2: return .two
        case 3: return .three
        case 4: return .four
        case 5: return .five
        default: return .six
        }
    }
}

/// A block-level element produced by ``MarkdownConverter``.
///
/// `MarkdownBlock` is a type-erased representation of a Score block node that
/// can be stored in arrays and composed dynamically. Each case maps to a
/// specific Score node type at render time.
public enum MarkdownBlock: Sendable {

    /// A heading at the specified level with inline children.
    case heading(level: HeadingLevel, children: [MarkdownInline])

    /// A paragraph with inline children.
    case paragraph(children: [MarkdownInline])

    /// A fenced code block.
    case codeBlock(code: String, language: String?, theme: SyntaxTheme)

    /// A math block rendered as MathML.
    case math(latex: String)

    /// A block quotation containing nested blocks.
    case blockquote(children: [MarkdownBlock])

    /// An unordered (bulleted) list where each item is a sequence of blocks.
    case unorderedList(items: [[MarkdownBlock]])

    /// An ordered (numbered) list where each item is a sequence of blocks.
    case orderedList(items: [[MarkdownBlock]])

    /// A thematic break (horizontal rule).
    case thematicBreak

    /// Raw HTML passed through without processing.
    case rawHTML(String)

    /// A table with header cells and body rows.
    case table(headers: [[MarkdownInline]], rows: [[[MarkdownInline]]])
}

/// An inline-level element produced by ``MarkdownConverter``.
///
/// `MarkdownInline` is a type-erased representation of a Score inline node
/// that can be stored in arrays and composed dynamically.
public enum MarkdownInline: Sendable {

    /// Plain text content.
    case text(String)

    /// Emphasised (italic) content with inline children.
    case emphasis(children: [MarkdownInline])

    /// Strong (bold) content with inline children.
    case strong(children: [MarkdownInline])

    /// Inline code span.
    case code(String)

    /// A hyperlink with a destination URL and inline children.
    case link(destination: String, children: [MarkdownInline])

    /// An image with source URL and alt text.
    case image(src: String, alt: String)

    /// A hard line break.
    case lineBreak

    /// Raw inline HTML passed through without processing.
    case rawInlineHTML(String)
}
