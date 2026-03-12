/// Utilities for converting Swift type names to CSS class names.
public struct CSSNaming: Sendable {

    private init() {}

    /// Converts a Swift type name to a kebab-case CSS class name.
    ///
    /// Strips common suffixes (`Page`, `Component`, `Layout`, `View`) and
    /// converts `UpperCamelCase` to `kebab-case`.
    ///
    /// ```swift
    /// CSSNaming.className(from: "FeatureCard")   // "feature-card"
    /// CSSNaming.className(from: "HomePage")       // "home"
    /// CSSNaming.className(from: "SiteHeader")     // "site-header"
    /// CSSNaming.className(from: "DocsLayout")     // "docs"
    /// ```
    public static func className(from typeName: String) -> String {
        // Strip generic parameters: "SiteLayout<TupleNode<...>>" → "SiteLayout"
        var name: String
        if let angleBracket = typeName.firstIndex(of: "<") {
            name = String(typeName[typeName.startIndex..<angleBracket])
        } else {
            name = typeName
        }

        // Strip common suffixes
        for suffix in ["Page", "Component", "Layout", "View"] {
            if name.hasSuffix(suffix) && name.count > suffix.count {
                name = String(name.dropLast(suffix.count))
                break
            }
        }

        // Split on uppercase boundaries and convert to kebab-case
        var parts: [String] = []
        var current = ""
        for char in name {
            if char.isUppercase && !current.isEmpty {
                parts.append(current.lowercased())
                current = String(char)
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            parts.append(current.lowercased())
        }

        return parts.joined(separator: "-")
    }
}
