/// The horizontal alignment of text within its container.
///
/// Maps to the CSS `text-align` property.
public enum TextAlign: String, Sendable {
    case start
    case center
    case end
    case justify
}

/// A transformation applied to text characters before rendering.
///
/// Maps to the CSS `text-transform` property.
public enum TextTransform: String, Sendable {
    case none
    case uppercase
    case lowercase
    case capitalize
}

/// A decorative line applied to text content.
///
/// Maps to the CSS `text-decoration` property.
public enum TextDecoration: String, Sendable {
    case none
    case underline
    case lineThrough = "line-through"
    case overline
}

/// The wrapping behavior applied to text that exceeds its container's width.
///
/// Maps to the CSS `text-wrap` property.
public enum TextWrap: String, Sendable {
    case wrap
    case nowrap
    case balance
    case pretty
}

/// Controls how white space and line breaks within an element are handled.
///
/// Maps to the CSS `white-space` property.
public enum WhiteSpace: String, Sendable {
    case normal
    case nowrap
    case pre
    case preWrap = "pre-wrap"
    case preLine = "pre-line"
    case breakSpaces = "break-spaces"
}

/// How overflowing text is visually indicated when it cannot fit in its container.
///
/// Maps to the CSS `text-overflow` property.
public enum TextOverflow: String, Sendable {
    case clip
    case ellipsis
}

/// How the browser handles line-break opportunities for text that overflows its container.
///
/// Maps to the CSS `overflow-wrap` property.
public enum OverflowWrap: String, Sendable {
    case normal
    case breakWord = "break-word"
    case anywhere
}

/// Controls how line breaks occur within words.
///
/// Maps to the CSS `word-break` property.
public enum WordBreak: String, Sendable {
    case normal
    case breakAll = "break-all"
    case keepAll = "keep-all"
    case breakWord = "break-word"
}

/// Controls whether the browser automatically inserts hyphens at line breaks.
///
/// Maps to the CSS `hyphens` property.
public enum Hyphens: String, Sendable {
    case none
    case manual
    case auto
}

/// A unified modifier for all typographic properties: font, color, and text style.
///
/// Consolidates font family, size, weight, tracking, line height, color,
/// alignment, transformation, decoration, wrapping, white-space, overflow,
/// word breaking, hyphenation, line clamping, and indentation into a single
/// `.font()` modifier. All properties are optional.
///
/// ### Example
///
/// ```swift
/// Heading(.one) { "Score" }
///     .font(.serif, size: 32, weight: .light, color: .text)
///
/// Link(to: "/docs") { "Read the docs" }
///     .font(size: 11, transform: .uppercase, decoration: .none)
/// ```
public struct FontModifier: ModifierValue {

    // Font properties
    public let family: FontFamily?
    public let size: Double?
    public let weight: FontWeight?
    public let tracking: Double?
    public let lineHeight: Double?
    public let color: ColorToken?

    // Text style properties
    public let align: TextAlign?
    public let transform: TextTransform?
    public let decoration: TextDecoration?
    public let wrap: TextWrap?
    public let whiteSpace: WhiteSpace?
    public let overflow: TextOverflow?
    public let overflowWrap: OverflowWrap?
    public let wordBreak: WordBreak?
    public let hyphens: Hyphens?
    public let lineClamp: Int?
    public let indent: Double?

    public init(
        _ family: FontFamily? = nil,
        size: Double? = nil,
        weight: FontWeight? = nil,
        tracking: Double? = nil,
        lineHeight: Double? = nil,
        color: ColorToken? = nil,
        align: TextAlign? = nil,
        transform: TextTransform? = nil,
        decoration: TextDecoration? = nil,
        wrap: TextWrap? = nil,
        whiteSpace: WhiteSpace? = nil,
        overflow: TextOverflow? = nil,
        overflowWrap: OverflowWrap? = nil,
        wordBreak: WordBreak? = nil,
        hyphens: Hyphens? = nil,
        lineClamp: Int? = nil,
        indent: Double? = nil
    ) {
        self.family = family
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.color = color
        self.align = align
        self.transform = transform
        self.decoration = decoration
        self.wrap = wrap
        self.whiteSpace = whiteSpace
        self.overflow = overflow
        self.overflowWrap = overflowWrap
        self.wordBreak = wordBreak
        self.hyphens = hyphens
        self.lineClamp = lineClamp
        self.indent = indent
    }
}

/// The typeface family used to render text within a node.
///
/// Provides semantic aliases for the most common typeface categories
/// as well as a `.custom` case for arbitrary font stacks.
public indirect enum FontFamily: Sendable {
    case system
    case sans
    case mono
    case serif
    case brand
    case custom(String, fallback: FontFamily)
}

/// The weight (thickness) of a font's strokes.
public enum FontWeight: String, Sendable {
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case black
}

extension Node {
    /// Applies typographic styling to this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Heading(.one) { "Score" }
    ///     .font(.serif, size: 32, weight: .light, color: .text)
    ///
    /// Paragraph { "Muted caption" }
    ///     .font(size: 11, color: .muted, align: .center, transform: .uppercase)
    /// ```
    public func font(
        _ family: FontFamily? = nil,
        size: Double? = nil,
        weight: FontWeight? = nil,
        tracking: Double? = nil,
        lineHeight: Double? = nil,
        color: ColorToken? = nil,
        align: TextAlign? = nil,
        transform: TextTransform? = nil,
        decoration: TextDecoration? = nil,
        wrap: TextWrap? = nil,
        whiteSpace: WhiteSpace? = nil,
        overflow: TextOverflow? = nil,
        overflowWrap: OverflowWrap? = nil,
        wordBreak: WordBreak? = nil,
        hyphens: Hyphens? = nil,
        lineClamp: Int? = nil,
        indent: Double? = nil
    ) -> ModifiedNode<Self> {
        let mod = FontModifier(
            family,
            size: size,
            weight: weight,
            tracking: tracking,
            lineHeight: lineHeight,
            color: color,
            align: align,
            transform: transform,
            decoration: decoration,
            wrap: wrap,
            whiteSpace: whiteSpace,
            overflow: overflow,
            overflowWrap: overflowWrap,
            wordBreak: wordBreak,
            hyphens: hyphens,
            lineClamp: lineClamp,
            indent: indent
        )
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
