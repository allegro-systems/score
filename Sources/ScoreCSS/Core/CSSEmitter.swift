import ScoreCore

/// Converts `ModifierValue` instances into CSS declarations.
///
/// `CSSEmitter` dispatches to each modifier's own `CSSRepresentable` conformance
/// and exposes shared CSS formatting utilities used by those conformances.
///
/// ### Example
///
/// ```swift
/// let declarations = CSSEmitter.declarations(for: PaddingModifier(16))
/// // [CSSDeclaration(property: "padding", value: "16px")]
/// ```
public struct CSSEmitter {

    private init() {}

    /// Produces CSS declarations for the given modifier value.
    ///
    /// Dispatches via `CSSRepresentable` to the modifier's own implementation.
    /// Returns an empty array for modifier types that have no CSS representation
    /// (such as accessibility modifiers that map to HTML attributes only).
    ///
    /// - Parameter modifier: The modifier value to convert.
    /// - Returns: An array of CSS declarations.
    public static func declarations(for modifier: any ModifierValue) -> [CSSDeclaration] {
        (modifier as? CSSRepresentable)?.cssDeclarations() ?? []
    }
}

// MARK: - Formatting utilities

extension CSSEmitter {

    /// Formats a point value as a CSS `px` string, omitting the decimal for whole numbers.
    static func pixels(_ value: Double) -> String { "\(value.cleanValue)px" }

    /// Formats a unitless number, omitting the decimal for whole numbers.
    static func number(_ value: Double) -> String { value.cleanValue }

    /// Formats a duration value as a CSS `s` string, omitting the decimal for whole seconds.
    static func seconds(_ value: Double) -> String { "\(value.cleanValue)s" }

    /// Produces `padding-*` or `margin-*` declarations for the given edges, or a
    /// shorthand declaration when no edges are specified.
    static func spacingDeclarations(_ base: String, value: Double, edges: Set<Edge>?) -> [CSSDeclaration] {
        guard let edges, !edges.isEmpty else {
            return [CSSDeclaration(property: base, value: pixels(value))]
        }
        return edges.map { edge in
            CSSDeclaration(property: "\(base)-\(edge.cssSuffix)", value: pixels(value))
        }
    }
}

// MARK: - Edge + CSS

extension Edge {

    /// The CSS property suffix for this edge (e.g. `"top"`, `"inline-start"`).
    var cssSuffix: String {
        switch self {
        case .top: return "top"
        case .bottom: return "bottom"
        case .leading: return "inline-start"
        case .trailing: return "inline-end"
        case .horizontal: return "inline"
        case .vertical: return "block"
        }
    }
}

// MARK: - FontFamily + CSS

extension FontFamily {

    /// Renders this font family as a CSS `font-family` value.
    var cssValue: String {
        switch self {
        case .system: return "system-ui, -apple-system, sans-serif"
        case .sans: return "var(--font-sans)"
        case .mono: return "var(--font-mono)"
        case .serif: return "var(--font-serif)"
        case .brand: return "var(--font-brand)"
        case .custom(let name, let fallback): return "\"\(name)\", \(fallback.cssValue)"
        }
    }
}

// MARK: - FontWeight + CSS

extension FontWeight {

    /// Renders this font weight as a CSS numeric value.
    var cssValue: String {
        switch self {
        case .thin: return "100"
        case .light: return "300"
        case .regular: return "400"
        case .medium: return "500"
        case .semibold: return "600"
        case .bold: return "700"
        case .black: return "900"
        }
    }
}
