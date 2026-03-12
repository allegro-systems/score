import ScoreCore

/// A composite node that renders a fenced code block with syntax highlighting,
/// an optional filename header, a copy button, and line numbers.
///
/// `CodeBlock` is the primary way to present source code in Score content. It
/// wraps the code in a `<pre><code>` structure and adds optional chrome: a
/// header bar showing the filename and language, a copy-to-clipboard button,
/// sequential line numbers, and a customisable footer area.
///
/// ```swift
/// CodeBlock(
///     code: "let x = 42",
///     language: "swift",
///     filename: "main.swift",
///     theme: .scoreDefault
/// )
/// ```
public struct CodeBlock: Node {

    /// The raw source code string displayed in the block.
    public let code: String

    /// The programming language identifier used for syntax highlighting.
    ///
    /// This value is typically the info string from a Markdown fenced code
    /// block (e.g. `"swift"`, `"python"`, `"html"`). When `nil`, no language-
    /// specific highlighting is applied.
    public let language: String?

    /// An optional filename displayed in the header bar above the code.
    ///
    /// When set, a header element is rendered showing this filename alongside
    /// the language identifier and a copy button.
    public let filename: String?

    /// The syntax theme that determines token colours.
    ///
    /// Defaults to ``SyntaxTheme/scoreDefault`` when not specified.
    public let theme: SyntaxTheme

    /// Whether the block displays line numbers alongside the code.
    public let showsLineNumbers: Bool

    /// Whether the block displays a copy-to-clipboard button.
    public let showsCopyButton: Bool

    /// Whether the block displays the header bar above the code.
    ///
    /// When `false`, the header bar (language label, filename, copy button) is
    /// suppressed even if `language`, `filename`, or `showsCopyButton` are set.
    /// Use this when embedding a code block inside a container that provides
    /// its own header chrome.
    public let showsHeader: Bool

    /// Creates a code block with the given configuration.
    ///
    /// - Parameters:
    ///   - code: The source code to display.
    ///   - language: The language identifier for highlighting. Defaults to `nil`.
    ///   - filename: An optional filename shown in the header. Defaults to `nil`.
    ///   - theme: The syntax colour theme. Defaults to ``SyntaxTheme/scoreDefault``.
    ///   - showsLineNumbers: Whether to show line numbers. Defaults to `true`.
    ///   - showsCopyButton: Whether to show a copy button. Defaults to `true`.
    ///   - showsHeader: Whether to show the header bar. Defaults to `true`.
    public init(
        code: String,
        language: String? = nil,
        filename: String? = nil,
        theme: SyntaxTheme = .scoreDefault,
        showsLineNumbers: Bool = true,
        showsCopyButton: Bool = true,
        showsHeader: Bool = true
    ) {
        self.code = code
        self.language = language
        self.filename = filename
        self.theme = theme
        self.showsLineNumbers = showsLineNumbers
        self.showsCopyButton = showsCopyButton
        self.showsHeader = showsHeader
    }

    public var body: some Node {
        RawTextNode(renderHTML())
    }

    private func renderHTML() -> String {
        let trimmedCode =
            code.hasSuffix("\n")
            ? String(code.dropLast())
            : code
        let lines = trimmedCode.split(separator: "\n", omittingEmptySubsequences: false)
        let tokens = SyntaxHighlighter.tokenize(trimmedCode, language: language)
        let codeId = "cb-\(abs(trimmedCode.hashValue))"

        var html = ""
        if showsHeader {
            html.append("<div data-code-block>")
        } else {
            html.append("<div data-code-block data-code-embedded>")
        }

        let hasHeader = showsHeader && (filename != nil || language != nil || showsCopyButton)
        if hasHeader {
            html.append("<div data-code-header>")
            html.append("<span data-code-label>")
            if let filename {
                html.append(escapeHTML(filename))
            } else if let language {
                html.append(escapeHTML(language))
            }
            html.append("</span>")
            if showsCopyButton {
                html.append(
                    """
                    <button data-code-copy onclick="navigator.clipboard.writeText(\
                    document.getElementById(&quot;\(codeId)&quot;).textContent)\
                    .then(function(){var b=this;b.textContent=&quot;Copied!&quot;;\
                    setTimeout(function(){b.textContent=&quot;Copy&quot;},1500)}\
                    .bind(this))">Copy</button>
                    """)
            }
            html.append("</div>")
        }

        html.append(
            "<pre id=\"\(codeId)\" data-code-source>\(escapeHTML(trimmedCode))</pre>"
        )

        let gridColumns = showsLineNumbers ? "auto 1fr" : "1fr"
        html.append(
            "<div data-code-grid style=\"grid-template-columns: \(gridColumns);\">"
        )

        let lineHTMLs = splitTokensIntoLines(tokens: tokens, lineCount: max(lines.count, 1))

        if showsLineNumbers {
            html.append("<div data-line-numbers>")
            for i in 0..<lineHTMLs.count {
                html.append("<span data-line-number>\(i + 1)</span>")
            }
            html.append("</div>")
        }

        html.append("<div data-code-lines>")
        for lineHTML in lineHTMLs {
            html.append("<code data-code-line>\(lineHTML)</code>")
        }
        html.append("</div>")

        html.append("</div></div>")

        return html
    }

    private func splitTokensIntoLines(
        tokens: [SyntaxToken], lineCount: Int
    ) -> [String] {
        var result = Array(repeating: "", count: lineCount)
        var currentLine = 0

        for token in tokens {
            let color = cssColor(for: token.category)
            let parts = token.text.split(separator: "\n", omittingEmptySubsequences: false)

            for (j, part) in parts.enumerated() {
                if j > 0 {
                    currentLine += 1
                    if currentLine >= lineCount { break }
                }
                guard currentLine < lineCount else { break }

                let escaped = escapeHTML(String(part))
                if !escaped.isEmpty {
                    if let color {
                        result[currentLine] += "<span style=\"color: \(color);\">\(escaped)</span>"
                    } else {
                        result[currentLine] +=
                            "<span style=\"color: \(theme.variable.cssValue);\">\(escaped)</span>"
                    }
                }
            }
        }

        return result
    }

    private func cssColor(for category: TokenCategory) -> String? {
        switch category {
        case .keyword: theme.keyword.cssValue
        case .string: theme.string.cssValue
        case .comment: theme.comment.cssValue
        case .number: theme.number.cssValue
        case .type: theme.type.cssValue
        case .function: theme.function.cssValue
        case .operator: theme.operatorColor.cssValue
        case .variable: theme.variable.cssValue
        case .plain: nil
        }
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
