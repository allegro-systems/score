import ScoreCore

/// The programming language for a ``TextEditor``.
///
/// Each language has an associated TreeSitter grammar WASM and
/// an LSP adapter strategy.
public enum EditorLanguage: String, Sendable {

    /// Swift source code.
    case swift

    /// TypeScript source code.
    case typescript

    /// C source code.
    case c

    /// Shell / Bash script.
    case shell
}

/// A code editor with TreeSitter syntax highlighting and LSP intelligence.
///
/// `TextEditor` renders as a layered structure:
/// - A transparent `<textarea>` captures keyboard input
/// - A `<pre><code>` overlay displays syntax-highlighted tokens
/// - An autocomplete popup and diagnostic overlay are managed by
///   the Score editor runtime (`score-editor.js` and `score-lsp.js`)
///
/// TreeSitter WASM provides incremental parsing and syntax highlighting
/// for all supported languages. The LSP layer provides autocomplete,
/// diagnostics, hover info, and go-to-definition using per-language
/// adapters (TypeScript compiler API, clangd WASM, TreeSitter-based
/// intelligence for Swift, bash-language-server for Shell).
///
/// ### Example
///
/// ```swift
/// TextEditor(
///     language: .swift,
///     content: "import Foundation\n\nprint(\"Hello, world!\")",
///     lineNumbers: true
/// )
///
/// TextEditor(language: .typescript, readOnly: true) // Empty read-only editor
/// ```
public struct TextEditor: Component {

    /// The programming language for syntax highlighting and LSP.
    public let language: EditorLanguage

    /// The text content of the editor.
    @State public var content: String

    /// Whether line numbers are shown in the gutter.
    public let lineNumbers: Bool

    /// Whether the editor is read-only.
    public let readOnly: Bool

    /// Whether the LSP adapter is enabled for this editor.
    public let lspEnabled: Bool

    /// Fires when the editor content changes.
    @Action public var onChange = {}

    /// Creates a code editor.
    ///
    /// - Parameters:
    ///   - language: The programming language. Defaults to `.swift`.
    ///   - content: The initial text content. Defaults to `""`.
    ///   - lineNumbers: Whether to show line numbers. Defaults to `true`.
    ///   - readOnly: Whether the editor is read-only. Defaults to `false`.
    ///   - lsp: Whether to enable the LSP adapter. Defaults to `true`.
    public init(
        language: EditorLanguage = .swift,
        content: String = "",
        lineNumbers: Bool = true,
        readOnly: Bool = false,
        lsp: Bool = true
    ) {
        self.language = language
        self._content = State(wrappedValue: content)
        self.lineNumbers = lineNumbers
        self.readOnly = readOnly
        self.lspEnabled = lsp
    }

    public var body: some Node {
        Stack {
            if lineNumbers {
                Stack {
                    EmptyNode()
                }
                .dataAttribute("part", "gutter")
                .accessibility(hidden: true)
            }
            Stack {
                TextArea(
                    name: "editor-input",
                    value: content,
                    id: "editor-\(language.rawValue)",
                    readOnly: readOnly
                )
                .dataAttribute("part", "input")
                .accessibility(label: "\(language.rawValue) code editor")
                Preformatted {
                    Code {
                        EmptyNode()
                    }
                }
                .dataAttribute("part", "highlight")
                .accessibility(hidden: true)
                Stack {
                    EmptyNode()
                }
                .dataAttribute("part", "autocomplete")
                .dataAttribute("state", "closed")
                .accessibility(role: "listbox")
                Stack {
                    EmptyNode()
                }
                .dataAttribute("part", "diagnostics")
                .accessibility(hidden: true)
                Stack {
                    EmptyNode()
                }
                .dataAttribute("part", "hover")
                .dataAttribute("state", "closed")
                .accessibility(role: "tooltip")
            }
            .dataAttribute("part", "content")
        }
        .dataAttribute("component", "editor")
        .dataAttribute("language", language.rawValue)
        .dataAttribute("lsp", lspEnabled ? "true" : "false")
        .dataAttribute("line-numbers", lineNumbers ? "true" : "false")
        .on(.input, "onChange")
    }
}
