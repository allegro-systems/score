import ScoreCore

/// A token produced by the syntax highlighter, pairing a text fragment with
/// its semantic category.
public struct SyntaxToken: Sendable {

    /// The category of this token, used to select the appropriate theme colour.
    public let category: TokenCategory

    /// The raw text content of the token.
    public let text: String

    /// Creates a syntax token.
    ///
    /// - Parameters:
    ///   - category: The semantic category of the token.
    ///   - text: The raw text content.
    public init(_ category: TokenCategory, _ text: String) {
        self.category = category
        self.text = text
    }
}

/// Semantic categories for syntax tokens, mapping to ``SyntaxTheme`` properties.
public enum TokenCategory: String, Sendable {

    /// Language keywords such as `if`, `let`, `func`, `class`.
    case keyword

    /// String literals including quoted text.
    case string

    /// Code comments (line and block).
    case comment

    /// Numeric literals (integers and floating-point).
    case number

    /// Type names, annotations, and protocol names.
    case type

    /// Function and method names at call sites.
    case function

    /// Operators such as `+`, `=`, `->`.
    case `operator`

    /// Variable and parameter names.
    case variable

    /// Plain text with no special highlighting.
    case plain
}

/// A regex-based syntax highlighter that tokenises source code for
/// Swift, HTML, CSS, and JavaScript.
///
/// `SyntaxHighlighter` produces an array of ``SyntaxToken`` values from a
/// source string. Each token carries a ``TokenCategory`` that maps directly
/// to a ``SyntaxTheme`` colour property, enabling server-side syntax
/// highlighting in ``CodeBlock``.
///
/// ```swift
/// let tokens = SyntaxHighlighter.tokenize("let x = 42", language: "swift")
/// ```
public struct SyntaxHighlighter: Sendable {

    private init() {}

    /// Tokenises the given source code using rules for the specified language.
    ///
    /// If the language is `nil` or unsupported, the entire string is returned
    /// as a single `.plain` token.
    ///
    /// - Parameters:
    ///   - source: The source code to tokenise.
    ///   - language: The language identifier (e.g. `"swift"`, `"html"`,
    ///     `"css"`, `"js"` or `"javascript"`).
    /// - Returns: An array of ``SyntaxToken`` values covering the entire input.
    public static func tokenize(_ source: String, language: String?) -> [SyntaxToken] {
        guard let language = language?.lowercased() else {
            return [SyntaxToken(.plain, source)]
        }

        let rules: [HighlightRule]
        switch language {
        case "swift":
            rules = swiftRules
        case "html":
            rules = htmlRules
        case "css":
            rules = cssRules
        case "js", "javascript":
            rules = jsRules
        default:
            return [SyntaxToken(.plain, source)]
        }

        return tokenize(source, rules: rules)
    }
}

// MARK: - Tokenisation Engine

extension SyntaxHighlighter {

    struct HighlightRule: Sendable {
        let pattern: String
        let category: TokenCategory
    }

    private static func tokenize(_ source: String, rules: [HighlightRule]) -> [SyntaxToken] {
        guard !source.isEmpty else { return [] }

        var matches: [(range: Range<String.Index>, category: TokenCategory)] = []

        for rule in rules {
            guard let regex = try? Regex(rule.pattern).dotMatchesNewlines(rule.category == .comment || rule.category == .string)
            else { continue }

            for match in source.matches(of: regex) {
                matches.append((match.range, rule.category))
            }
        }

        matches.sort { $0.range.lowerBound < $1.range.lowerBound }

        var tokens: [SyntaxToken] = []
        var cursor = source.startIndex

        for match in matches {
            guard match.range.lowerBound >= cursor else { continue }

            if match.range.lowerBound > cursor {
                let plain = String(source[cursor..<match.range.lowerBound])
                if !plain.isEmpty {
                    tokens.append(SyntaxToken(.plain, plain))
                }
            }

            let text = String(source[match.range])
            tokens.append(SyntaxToken(match.category, text))
            cursor = match.range.upperBound
        }

        if cursor < source.endIndex {
            let remaining = String(source[cursor...])
            if !remaining.isEmpty {
                tokens.append(SyntaxToken(.plain, remaining))
            }
        }

        return tokens
    }
}

// MARK: - Swift Rules

extension SyntaxHighlighter {

    static let swiftRules: [HighlightRule] = [
        HighlightRule(pattern: #"//[^\n]*"#, category: .comment),
        HighlightRule(pattern: #"/\*[\s\S]*?\*/"#, category: .comment),
        HighlightRule(pattern: #"\"\"\"[\s\S]*?\"\"\""#, category: .string),
        HighlightRule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, category: .string),
        HighlightRule(
            pattern:
                #"\b(?:actor|associatedtype|async|await|break|case|catch|class|continue|default|defer|deinit|do|else|enum|extension|fallthrough|fileprivate|final|for|func|guard|if|import|in|init|inout|internal|lazy|let|mutating|nonisolated|open|operator|override|precedencegroup|private|protocol|public|repeat|rethrows|return|sending|self|some|static|struct|subscript|super|switch|throws?|try|typealias|var|where|while)\b"#,
            category: .keyword
        ),
        HighlightRule(pattern: #"@\w+"#, category: .keyword),
        HighlightRule(pattern: #"\b(?:0[xX][0-9a-fA-F_]+|0[oO][0-7_]+|0[bB][01_]+|\d[\d_]*(?:\.[\d_]+)?(?:[eE][+-]?\d+)?)\b"#, category: .number),
        HighlightRule(
            pattern:
                #"\b(?:Bool|Character|Double|Float|Int|Int8|Int16|Int32|Int64|Never|Optional|Result|String|UInt|UInt8|UInt16|UInt32|UInt64|Void|Array|Dictionary|Set|any|Self|Type|Error|Sendable|Hashable|Equatable|Codable|Identifiable|CustomStringConvertible)\b"#,
            category: .type),
        HighlightRule(pattern: #"\b(?:true|false|nil)\b"#, category: .keyword),
        HighlightRule(pattern: #"\b[A-Z][A-Za-z0-9]*\b"#, category: .type),
        HighlightRule(pattern: #"\b[a-z_]\w*(?=\s*\()"#, category: .function),
        HighlightRule(pattern: #"[+\-*/%=!<>&|^~?]+|->|\.\.\.|\.\.(?=<)"#, category: .operator),
    ]
}

// MARK: - HTML Rules

extension SyntaxHighlighter {

    static let htmlRules: [HighlightRule] = [
        HighlightRule(pattern: #"<!--[\s\S]*?-->"#, category: .comment),
        HighlightRule(pattern: #""[^"]*""#, category: .string),
        HighlightRule(pattern: #"'[^']*'"#, category: .string),
        HighlightRule(pattern: #"</?[a-zA-Z][\w-]*"#, category: .keyword),
        HighlightRule(pattern: #"/?\s*>"#, category: .keyword),
        HighlightRule(pattern: #"\b[a-zA-Z][\w-]*(?=\s*=)"#, category: .variable),
        HighlightRule(pattern: #"&\w+;"#, category: .number),
    ]
}

// MARK: - CSS Rules

extension SyntaxHighlighter {

    static let cssRules: [HighlightRule] = [
        HighlightRule(pattern: #"/\*[\s\S]*?\*/"#, category: .comment),
        HighlightRule(pattern: #""[^"]*""#, category: .string),
        HighlightRule(pattern: #"'[^']*'"#, category: .string),
        HighlightRule(pattern: #"@(?:media|import|keyframes|font-face|supports|charset|namespace|layer)\b"#, category: .keyword),
        HighlightRule(pattern: #"!important\b"#, category: .keyword),
        HighlightRule(pattern: #"#[0-9a-fA-F]{3,8}\b"#, category: .number),
        HighlightRule(pattern: #"\b\d+(?:\.\d+)?(?:px|em|rem|%|vh|vw|vmin|vmax|ch|ex|cm|mm|in|pt|pc|s|ms|deg|rad|turn|fr)\b"#, category: .number),
        HighlightRule(pattern: #"\b\d+(?:\.\d+)?\b"#, category: .number),
        HighlightRule(pattern: #"[a-zA-Z][\w-]*(?=\s*\()"#, category: .function),
        HighlightRule(pattern: #"[\w-]+(?=\s*:)"#, category: .variable),
        HighlightRule(pattern: #"[.#][\w-]+"#, category: .type),
        HighlightRule(pattern: #"::?[\w-]+"#, category: .keyword),
    ]
}

// MARK: - JavaScript Rules

extension SyntaxHighlighter {

    static let jsRules: [HighlightRule] = [
        HighlightRule(pattern: #"//[^\n]*"#, category: .comment),
        HighlightRule(pattern: #"/\*[\s\S]*?\*/"#, category: .comment),
        HighlightRule(pattern: #"`(?:[^`\\]|\\.)*`"#, category: .string),
        HighlightRule(pattern: #""[^"\\]*(?:\\.[^"\\]*)*""#, category: .string),
        HighlightRule(pattern: #"'[^'\\]*(?:\\.[^'\\]*)*'"#, category: .string),
        HighlightRule(
            pattern:
                #"\b(?:async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|from|function|if|import|in|instanceof|let|new|of|return|static|super|switch|this|throw|try|typeof|var|void|while|with|yield)\b"#,
            category: .keyword
        ),
        HighlightRule(pattern: #"\b(?:true|false|null|undefined|NaN|Infinity)\b"#, category: .keyword),
        HighlightRule(pattern: #"\b(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|0[bB][01]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b"#, category: .number),
        HighlightRule(pattern: #"\b[A-Z][A-Za-z0-9]*\b"#, category: .type),
        HighlightRule(pattern: #"\b[a-z_$]\w*(?=\s*\()"#, category: .function),
        HighlightRule(pattern: #"[+\-*/%=!<>&|^~?]+|=>|\.\.\."#, category: .operator),
    ]
}
