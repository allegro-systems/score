/// The context in which a string is being embedded within an HTML document.
///
/// The escape context determines which characters must be replaced with
/// HTML entity references. Attribute values require additional escaping
/// of double-quote characters beyond what text content needs.
package enum HTMLEscapeContext {
    /// The string will be used as text content between HTML tags.
    case text
    /// The string will be used inside a double-quoted HTML attribute value.
    case attribute
}

extension String {

    /// Returns a copy of this string with HTML-special characters replaced
    /// by entity references appropriate for the given context.
    ///
    /// - Parameter context: Whether the string is destined for text content
    ///   or an attribute value.
    /// - Returns: An escaped string safe for embedding in the specified
    ///   HTML context.
    package func escaped(for context: HTMLEscapeContext) -> String {
        var result = ""
        result.reserveCapacity(count)

        for char in self {
            switch char {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"" where context == .attribute:
                result += "&quot;"
            case "'" where context == .attribute:
                result += "&#39;"
            default:
                result.append(char)
            }
        }

        return result
    }

    /// A copy of this string with `&`, `<`, and `>` escaped for safe use
    /// as text content within an HTML document.
    package var htmlEscaped: String {
        escaped(for: .text)
    }

    /// A copy of this string with `&`, `<`, `>`, `"`, and `'` escaped for safe
    /// use inside a double-quoted HTML attribute value.
    package var attributeEscaped: String {
        escaped(for: .attribute)
    }
}
