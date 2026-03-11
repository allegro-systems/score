/// Minimal file-level minification for CSS, JavaScript, and HTML output.
///
/// These are lightweight, regex-free transformations that strip whitespace,
/// comments, and newlines to produce single-line output. They are not
/// full-featured minifiers but sufficient for the output Score generates.
public struct Minifier: Sendable {

    private init() {}

    /// Minifies a CSS string by stripping comments, collapsing whitespace,
    /// and removing unnecessary characters.
    public static func minifyCSS(_ css: String) -> String {
        var result = ""
        result.reserveCapacity(css.count)

        var index = css.startIndex
        let end = css.endIndex

        while index < end {
            let char = css[index]

            // Skip block comments
            if char == "/", css.index(after: index) < end, css[css.index(after: index)] == "*" {
                if let closeRange = css.range(of: "*/", range: css.index(index, offsetBy: 2)..<end) {
                    index = closeRange.upperBound
                    continue
                }
            }

            // Preserve quoted strings
            if char == "\"" || char == "'" {
                let quote = char
                result.append(quote)
                index = css.index(after: index)
                while index < end, css[index] != quote {
                    if css[index] == "\\" {
                        result.append(css[index])
                        index = css.index(after: index)
                        guard index < end else { break }
                    }
                    result.append(css[index])
                    index = css.index(after: index)
                }
                if index < end {
                    result.append(quote)
                    index = css.index(after: index)
                }
                continue
            }

            // Collapse whitespace
            if char.isWhitespace || char.isNewline {
                index = css.index(after: index)
                while index < end, css[index].isWhitespace || css[index].isNewline {
                    index = css.index(after: index)
                }
                // Only keep a space when needed between tokens
                if !result.isEmpty, let last = result.last,
                    !isCSSSeparator(last), index < end, !isCSSSeparator(css[index])
                {
                    result.append(" ")
                }
                continue
            }

            result.append(char)
            index = css.index(after: index)
        }

        return result
    }

    /// Minifies a JavaScript string by stripping single-line comments,
    /// collapsing whitespace, and removing unnecessary newlines.
    public static func minifyJS(_ js: String) -> String {
        var result = ""
        result.reserveCapacity(js.count)

        var index = js.startIndex
        let end = js.endIndex

        while index < end {
            let char = js[index]

            // Skip single-line comments
            if char == "/", js.index(after: index) < end, js[js.index(after: index)] == "/" {
                while index < end, js[index] != "\n" {
                    index = js.index(after: index)
                }
                continue
            }

            // Skip block comments
            if char == "/", js.index(after: index) < end, js[js.index(after: index)] == "*" {
                if let closeRange = js.range(of: "*/", range: js.index(index, offsetBy: 2)..<end) {
                    index = closeRange.upperBound
                    continue
                }
            }

            // Preserve quoted strings
            if char == "\"" || char == "'" || char == "`" {
                let quote = char
                result.append(quote)
                index = js.index(after: index)
                while index < end, js[index] != quote {
                    if js[index] == "\\" {
                        result.append(js[index])
                        index = js.index(after: index)
                        guard index < end else { break }
                    }
                    result.append(js[index])
                    index = js.index(after: index)
                }
                if index < end {
                    result.append(quote)
                    index = js.index(after: index)
                }
                continue
            }

            // Collapse whitespace and newlines
            if char.isWhitespace || char.isNewline {
                index = js.index(after: index)
                while index < end, js[index].isWhitespace || js[index].isNewline {
                    index = js.index(after: index)
                }
                // Keep space between tokens that need it
                if !result.isEmpty, let last = result.last,
                    isJSIdentifierChar(last), index < end, isJSIdentifierChar(js[index])
                {
                    result.append(" ")
                }
                continue
            }

            result.append(char)
            index = js.index(after: index)
        }

        return result
    }

    /// Minifies an HTML string by collapsing whitespace between tags and
    /// removing unnecessary newlines.
    public static func minifyHTML(_ html: String) -> String {
        var result = ""
        result.reserveCapacity(html.count)

        var index = html.startIndex
        let end = html.endIndex
        var inTag = false
        var inPreOrScript = false
        var tagName = ""

        while index < end {
            let char = html[index]

            if char == "<" {
                inTag = true
                tagName = ""
                result.append(char)
                index = html.index(after: index)

                // Read tag name
                let isClosing = index < end && html[index] == "/"
                if isClosing {
                    result.append(html[index])
                    index = html.index(after: index)
                }
                while index < end, html[index] != ">", html[index] != " ", !html[index].isWhitespace {
                    tagName.append(html[index])
                    result.append(html[index])
                    index = html.index(after: index)
                }

                let lower = tagName.lowercased()
                if isClosing {
                    if lower == "pre" || lower == "script" || lower == "style" || lower == "textarea" {
                        inPreOrScript = false
                    }
                } else {
                    if lower == "pre" || lower == "script" || lower == "style" || lower == "textarea" {
                        inPreOrScript = true
                    }
                }
                continue
            }

            if char == ">" {
                inTag = false
                result.append(char)
                index = html.index(after: index)
                continue
            }

            // Inside tags, collapse attribute whitespace
            if inTag {
                if char.isWhitespace || char.isNewline {
                    index = html.index(after: index)
                    while index < end, html[index].isWhitespace || html[index].isNewline {
                        index = html.index(after: index)
                    }
                    if index < end, html[index] != ">" {
                        result.append(" ")
                    }
                    continue
                }
                result.append(char)
                index = html.index(after: index)
                continue
            }

            // Outside tags, preserve pre/script/style content verbatim
            if inPreOrScript {
                result.append(char)
                index = html.index(after: index)
                continue
            }

            // Outside tags, collapse whitespace
            if char.isWhitespace || char.isNewline {
                index = html.index(after: index)
                while index < end, html[index].isWhitespace || html[index].isNewline {
                    index = html.index(after: index)
                }
                // Keep a single space between text nodes
                if !result.isEmpty, let last = result.last, last != ">",
                    index < end, html[index] != "<"
                {
                    result.append(" ")
                }
                continue
            }

            result.append(char)
            index = html.index(after: index)
        }

        return result
    }

    // MARK: - Helpers

    private static func isCSSSeparator(_ char: Character) -> Bool {
        switch char {
        case "{", "}", "(", ")", ";", ":", ",", ">", "+", "~": return true
        default: return false
        }
    }

    private static func isJSIdentifierChar(_ char: Character) -> Bool {
        char.isLetter || char.isNumber || char == "_" || char == "$"
    }
}
