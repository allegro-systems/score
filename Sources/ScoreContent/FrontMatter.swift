/// Parsed front matter metadata extracted from a content file.
///
/// `FrontMatter` parses `---`-delimited YAML-style key-value pairs found at
/// the top of Markdown and other content files. The parser handles simple
/// scalar values: strings (optionally quoted), numbers, and booleans.
///
/// ```
/// ---
/// title: Hello World
/// date: 2026-01-15
/// draft: false
/// tags: swift, score
/// ---
/// ```
///
/// ```swift
/// let fm = FrontMatter.parse(from: content)
/// let title = fm?.string("title")
/// ```
public struct FrontMatter: Sendable, Hashable {

    /// The raw key-value pairs extracted from the front matter block.
    public let values: [String: String]

    /// Creates a front matter instance with the given key-value dictionary.
    ///
    /// - Parameter values: A dictionary of metadata keys and their string values.
    public init(values: [String: String]) {
        self.values = values
    }

    /// Retrieves the string value for the given key, or `nil` if absent.
    ///
    /// - Parameter key: The metadata key to look up.
    /// - Returns: The associated string value, or `nil`.
    public func string(_ key: String) -> String? {
        values[key]
    }

    /// Retrieves the integer value for the given key, or `nil` if absent or
    /// not representable as an integer.
    ///
    /// - Parameter key: The metadata key to look up.
    /// - Returns: The associated integer value, or `nil`.
    public func integer(_ key: String) -> Int? {
        values[key].flatMap { Int($0) }
    }

    /// Retrieves the boolean value for the given key, or `nil` if absent.
    ///
    /// Recognises `"true"`, `"yes"`, `"1"` as `true` and `"false"`, `"no"`,
    /// `"0"` as `false` (case-insensitive).
    ///
    /// - Parameter key: The metadata key to look up.
    /// - Returns: The associated boolean value, or `nil`.
    public func bool(_ key: String) -> Bool? {
        guard let raw = values[key]?.lowercased() else { return nil }
        switch raw {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }

    /// Retrieves a comma-separated list value for the given key.
    ///
    /// Each element is trimmed of leading and trailing whitespace. Returns
    /// an empty array if the key is absent.
    ///
    /// - Parameter key: The metadata key to look up.
    /// - Returns: An array of trimmed string values.
    public func list(_ key: String) -> [String] {
        guard let raw = values[key] else { return [] }
        return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

extension FrontMatter {

    /// Parses front matter from the beginning of a content string.
    ///
    /// The front matter block must start with a line containing exactly `---`
    /// and end with a subsequent `---` line. Lines between the delimiters are
    /// parsed as `key: value` pairs.
    ///
    /// - Parameter content: The full content string, potentially starting with
    ///   a front matter block.
    /// - Returns: A `FrontMatter` instance if a valid block was found, or `nil`.
    public static func parse(from content: String) -> FrontMatter? {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first,
            firstLine.trimmingCharacters(in: .whitespaces) == "---"
        else {
            return nil
        }

        var values: [String: String] = [:]
        var foundEnd = false

        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" {
                foundEnd = true
                break
            }

            guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }
            let key = trimmed[..<colonIndex].trimmingCharacters(in: .whitespaces)
            let value = trimmed[trimmed.index(after: colonIndex)...]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: .init(charactersIn: "\"'"))

            if !key.isEmpty {
                values[key] = value
            }
        }

        guard foundEnd else { return nil }
        return FrontMatter(values: values)
    }

    /// Returns the content body after stripping the front matter block.
    ///
    /// If the content does not start with a front matter block, the entire
    /// string is returned unchanged.
    ///
    /// - Parameter content: The full content string.
    /// - Returns: The content body without the front matter delimiters and metadata.
    public static func body(from content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first,
            firstLine.trimmingCharacters(in: .whitespaces) == "---"
        else {
            return content
        }

        var endIndex = 0
        for (index, line) in lines.dropFirst().enumerated() {
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                endIndex = index + 2
                break
            }
        }

        guard endIndex > 0 else { return content }

        let bodyLines = Array(lines.dropFirst(endIndex))
        let body = bodyLines.joined(separator: "\n")
        if body.hasPrefix("\n") {
            return String(body.dropFirst())
        }
        return body
    }
}
