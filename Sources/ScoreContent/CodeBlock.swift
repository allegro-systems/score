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

    /// Whether to display line numbers alongside the code.
    public let showLineNumbers: Bool

    /// Whether to display a copy-to-clipboard button.
    public let showCopyButton: Bool

    /// Creates a code block with the given configuration.
    ///
    /// - Parameters:
    ///   - code: The source code to display.
    ///   - language: The language identifier for highlighting. Defaults to `nil`.
    ///   - filename: An optional filename shown in the header. Defaults to `nil`.
    ///   - theme: The syntax colour theme. Defaults to ``SyntaxTheme/scoreDefault``.
    ///   - showLineNumbers: Whether to show line numbers. Defaults to `true`.
    ///   - showCopyButton: Whether to show a copy button. Defaults to `true`.
    public init(
        code: String,
        language: String? = nil,
        filename: String? = nil,
        theme: SyntaxTheme = .scoreDefault,
        showLineNumbers: Bool = true,
        showCopyButton: Bool = true
    ) {
        self.code = code
        self.language = language
        self.filename = filename
        self.theme = theme
        self.showLineNumbers = showLineNumbers
        self.showCopyButton = showCopyButton
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
        html.append("<div style=\"background: \(theme.background.cssValue); border-radius: 6px; overflow: hidden; margin: 16px 0;\">")

        let hasHeader = filename != nil || language != nil || showCopyButton
        if hasHeader {
            html.append("<div style=\"display: flex; align-items: center; justify-content: space-between; padding: 6px 16px; border-bottom: 1px solid rgba(255,255,255,0.12);\">")
            html.append(
                "<span style=\"color: \(theme.comment.cssValue); font-family: var(--font-mono, monospace); font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em;\">")
            if let filename {
                html.append(escapeHTML(filename))
            } else if let language {
                html.append(escapeHTML(language))
            }
            html.append("</span>")
            if showCopyButton {
                html.append(
                    """
                    <button onclick="navigator.clipboard.writeText(document.getElementById(&quot;\(codeId)&quot;).textContent).then(function(){var b=this;b.textContent=&quot;Copied!&quot;;setTimeout(function(){b.textContent=&quot;Copy&quot;},1500)}.bind(this))" style="background: none; border: 1px solid rgba(255,255,255,0.15); color: \(theme.variable.cssValue); font-size: 10px; padding: 2px 8px; border-radius: 3px; cursor: pointer; font-family: var(--font-mono, monospace);">Copy</button>
                    """)
            }
            html.append("</div>")
        }

        // Hidden element for copy button
        html.append(
            "<pre id=\"\(codeId)\" style=\"position:absolute;left:-9999px;\">\(escapeHTML(trimmedCode))</pre>"
        )

        let gridColumns = showLineNumbers ? "auto 1fr" : "1fr"
        html.append(
            "<div style=\"display: grid; grid-template-columns: \(gridColumns); overflow-x: auto;\">"
        )

        let lineHTMLs = splitTokensIntoLines(tokens: tokens, lineCount: max(lines.count, 1))
        let mono = "font-family: var(--font-mono, monospace); font-size: 13px; line-height: 1.5;"

        for (i, lineHTML) in lineHTMLs.enumerated() {
            let top = i == 0 ? "12px" : "0"
            let bottom = i == lineHTMLs.count - 1 ? "12px" : "0"

            if showLineNumbers {
                html.append(
                    "<span style=\"\(mono) padding: \(top) 12px \(bottom) 12px; color: \(theme.comment.cssValue); text-align: right; user-select: none; -webkit-user-select: none; border-right: 1px solid rgba(255,255,255,0.10);\">\(i + 1)</span>"
                )
            }

            html.append(
                "<code style=\"\(mono) padding: \(top) 16px \(bottom) 16px; white-space: pre; background: none; border: none; border-radius: 0;\">\(lineHTML)</code>"
            )
        }

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
