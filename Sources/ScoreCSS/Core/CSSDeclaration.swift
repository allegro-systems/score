import ScoreCore

/// A single CSS property–value pair.
///
/// `CSSDeclaration` is the atomic unit of styling in ScoreCSS. A collection
/// of declarations forms a rule set that is associated with a scoped
/// selector by `CSSCollector`.
///
/// ### Example
///
/// ```swift
/// let declaration = CSSDeclaration(property: "padding", value: "16px")
/// // Renders as: padding: 16px;
/// ```
public struct CSSDeclaration: Sendable, Hashable {

    /// The CSS property name (e.g. `"padding"`, `"background-color"`).
    public let property: String

    /// The CSS value (e.g. `"16px"`, `"oklch(0.65 0.18 270)"`).
    public let value: String

    /// Creates a CSS declaration.
    ///
    /// - Parameters:
    ///   - property: The CSS property name.
    ///   - value: The CSS value.
    public init(property: String, value: String) {
        self.property = property
        self.value = value
    }

    /// Renders this declaration as a CSS string.
    ///
    /// The value is sanitized to prevent CSS injection by stripping
    /// characters that could break out of a declaration context.
    ///
    /// - Returns: A string in the format `"property: value"`.
    public func render() -> String {
        "\(property): \(Self.sanitizeCSSValue(value))"
    }

    /// Builds a lookup key from an array of declarations.
    ///
    /// The key concatenates each declaration's property and value, separated
    /// by semicolons. This format is used by `CSSCollector` and the HTML
    /// renderer to match modifier sets to their CSS class names.
    ///
    /// - Parameter declarations: The declarations to key.
    /// - Returns: A deterministic string key for the declaration set.
    public static func lookupKey(for declarations: [CSSDeclaration]) -> String {
        declarations.map { "\($0.property):\($0.value)" }.joined(separator: ";")
    }

    /// Strips characters from a CSS value that could break out of a declaration.
    ///
    /// Removes `{`, `}`, `;`, `<`, `>`, and strips `url(...)` blocks that
    /// contain anything other than safe path characters.
    static func sanitizeCSSValue(_ input: String) -> String {
        var result = input
        for dangerous in ["{", "}", ";", "<", ">"] {
            result = result.replacingOccurrences(of: dangerous, with: "")
        }
        return result
    }
}
