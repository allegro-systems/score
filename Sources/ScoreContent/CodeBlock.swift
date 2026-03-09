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
        Stack {
            if filename != nil || language != nil || showCopyButton {
                Stack {
                    if let filename {
                        Text { filename }
                    }
                    if let language {
                        Small { language }
                    }
                    if showCopyButton {
                        Button { "Copy" }
                    }
                }
            }
            if showLineNumbers {
                Stack {
                    Stack {
                        lineNumberBlock
                    }
                    Preformatted {
                        Code { code }
                    }
                }
            } else {
                Preformatted {
                    Code { code }
                }
            }
        }
    }

    /// The line-number column rendered as a series of small text elements.
    private var lineNumberBlock: some Node {
        let lineCount = code.components(separatedBy: "\n").count
        // swiftlint:disable:next unused_result
        return ForEachNode(Array(1...lineCount)) { number in
            Text { "\(number)" }
        }
    }
}
