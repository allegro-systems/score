import Markdown
import ScoreCore
import ScoreHTML

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
        let blocks = document.children.flatMap { convertBlock($0) }
        return groupTabs(blocks)
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

    /// Groups consecutive tab-marked code blocks into ``MarkdownBlock/tabGroup``
    /// entries during conversion.
    ///
    /// After block-level conversion, this method scans for runs of
    /// `.tabbedCodeBlock` entries and replaces each run with a single
    /// `.tabGroup`.
    func groupTabs(_ blocks: [MarkdownBlock]) -> [MarkdownBlock] {
        var result: [MarkdownBlock] = []
        var pendingTabs: [(label: String, code: String, language: String?)] = []

        func flushTabs() {
            guard !pendingTabs.isEmpty else { return }
            let renderer = HTMLRenderer()
            let tabs = pendingTabs.map { entry in
                let codeBlock = CodeBlock(
                    code: entry.code,
                    language: entry.language,
                    theme: theme,
                    showsCopyButton: false,
                    showsHeader: false
                )
                return Tab(label: entry.label, html: renderer.render(codeBlock))
            }
            result.append(.tabGroup(tabs: tabs))
            pendingTabs.removeAll()
        }

        for block in blocks {
            if case .tabbedCodeBlock(let code, let language, let label) = block {
                pendingTabs.append((label: label, code: code, language: language))
            } else {
                flushTabs()
                result.append(block)
            }
        }
        flushTabs()
        return result
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
            let code = codeBlock.code
            let parsed = parseInfoString(codeBlock.language)
            if parsed.language == "math" {
                return [.math(latex: code.trimmingCharacters(in: .whitespacesAndNewlines))]
            }
            if let tabLabel = parsed.tabLabel {
                return [.tabbedCodeBlock(code: code, language: parsed.language, label: tabLabel)]
            }
            return [.codeBlock(code: code, language: parsed.language, theme: theme)]

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

    /// Parses a fenced code block info string, extracting the language and an
    /// optional `tab` marker with a custom label.
    ///
    /// Supported formats:
    /// - `"swift"` → language `"swift"`, no tab
    /// - `"swift tab"` → language `"swift"`, tab label `"swift"`
    /// - `"html tab=\"Output\""` → language `"html"`, tab label `"Output"`
    func parseInfoString(_ infoString: String?) -> (language: String?, tabLabel: String?) {
        guard let info = infoString?.trimmingCharacters(in: .whitespaces),
            !info.isEmpty
        else {
            return (nil, nil)
        }

        let parts = info.split(separator: " ", maxSplits: 1)
        let language = String(parts[0])

        guard parts.count > 1 else {
            return (language, nil)
        }

        let rest = String(parts[1]).trimmingCharacters(in: .whitespaces)

        if rest == "tab" {
            return (language, language)
        }

        if rest.hasPrefix("tab=") {
            var label = String(rest.dropFirst(4))
            if label.hasPrefix("\"") && label.hasSuffix("\"") && label.count >= 2 {
                label = String(label.dropFirst().dropLast())
            }
            return (language, label.isEmpty ? language : label)
        }

        return (language, nil)
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

    /// A fenced code block marked with `tab` in the info string.
    ///
    /// This is an intermediate representation consumed by
    /// ``MarkdownConverter/groupTabs(_:)`` to produce ``tabGroup`` entries.
    /// It never appears in final output.
    case tabbedCodeBlock(code: String, language: String?, label: String)

    /// A group of tabbed code blocks rendered as a ``TabGroup``.
    case tabGroup(tabs: [Tab])
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
