/// Describes a local font file for `@font-face` generation.
///
/// Each `FontFace` maps a font file in the application's resources directory
/// to a CSS `@font-face` rule with the specified family name, weight, and style.
///
/// ```swift
/// var fontFaces: [FontFace] {
///     [
///         FontFace("Inter", resource: "fonts/Inter-Regular.woff2", weight: .regular),
///         FontFace("Inter", resource: "fonts/Inter-Bold.woff2", weight: .bold),
///         FontFace("Inter", resource: "fonts/Inter-Italic.woff2", isItalic: true),
///     ]
/// }
/// ```
public struct FontFace: Sendable {

    /// The CSS `font-family` name used in the generated `@font-face` rule.
    public let family: String

    /// The path to the font file relative to the application's resources directory.
    public let resource: String

    /// The font weight for this face.
    public let weight: FontWeight

    /// Whether this face is italic.
    public let isItalic: Bool

    /// Creates a font face descriptor.
    ///
    /// - Parameters:
    ///   - family: The CSS `font-family` name.
    ///   - resource: The path relative to the resources directory.
    ///   - weight: The font weight. Defaults to ``FontWeight/regular``.
    ///   - isItalic: Whether this face is italic. Defaults to `false`.
    public init(
        _ family: String,
        resource: String,
        weight: FontWeight = .regular,
        isItalic: Bool = false
    ) {
        self.family = family
        self.resource = resource
        self.weight = weight
        self.isItalic = isItalic
    }

    /// The CSS `font-weight` numeric value for this face.
    public var cssWeight: Int {
        switch weight {
        case .thin: return 100
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .black: return 900
        }
    }

    /// The CSS `format()` hint derived from the font file extension.
    ///
    /// Returns `nil` if the extension is not a recognised font format.
    public var cssFormat: String? {
        guard let dotIndex = resource.lastIndex(of: ".") else { return nil }
        let ext = String(resource[resource.index(after: dotIndex)...]).lowercased()
        switch ext {
        case "woff2": return "woff2"
        case "woff": return "woff"
        case "ttf": return "truetype"
        case "otf": return "opentype"
        default: return nil
        }
    }
}
