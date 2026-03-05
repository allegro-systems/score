import Foundation

extension String {
    /// Returns a normalized absolute-style route path.
    ///
    /// Leading and trailing whitespace/newlines are trimmed. Empty input
    /// becomes `/`. Non-empty input is guaranteed to begin with `/`.
    ///
    /// ```swift
    /// " users ".normalized() // "/users"
    /// "".normalized()         // "/"
    /// ```
    func normalized() -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "/" }
        var path = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        while path.contains("//") {
            path = path.replacingOccurrences(of: "//", with: "/")
        }
        if path.count > 1, path.hasSuffix("/") {
            path = String(path.dropLast())
        }
        return path
    }
}
