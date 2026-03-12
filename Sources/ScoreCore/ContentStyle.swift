/// Styling configuration for rendered Markdown content elements.
///
/// `ContentStyle` controls the visual presentation of inline and block-level
/// elements produced by ``MarkdownNode``. It follows the same pattern as
/// ``SyntaxTheme`` — a flat value type that the CSS emitter reads to produce
/// element-level styles.
///
/// Each property maps to a CSS declaration applied to the corresponding HTML
/// element. Properties use ``ColorToken`` so they automatically adapt to
/// light/dark themes via CSS custom properties.
///
/// ```swift
/// struct AppTheme: Theme {
///     var contentStyle: ContentStyle {
///         ContentStyle(
///             inlineCodeBackground: .border,
///             inlineCodeBorderColor: .border,
///             blockquoteBorderColor: .accent
///         )
///     }
/// }
/// ```
public struct ContentStyle: Sendable, Hashable {

    /// Background colour for inline `<code>` elements.
    public var inlineCodeBackground: ColorToken

    /// Border colour for inline `<code>` elements. Set to `nil` to omit the border.
    public var inlineCodeBorderColor: ColorToken?

    /// Corner radius for inline `<code>` elements, in pixels.
    public var inlineCodeRadius: Double

    /// Left border colour for `<blockquote>` elements.
    public var blockquoteBorderColor: ColorToken

    /// Background colour for `<blockquote>` elements. Set to `nil` for transparent.
    public var blockquoteBackground: ColorToken?

    /// Colour for `<hr>` (thematic break) elements.
    public var horizontalRuleColor: ColorToken

    /// Border colour for `<table>` elements and their cells.
    public var tableBorderColor: ColorToken

    /// Background colour for table header cells.
    public var tableHeaderBackground: ColorToken?

    /// Background colour for fenced code blocks. When `nil`, the syntax
    /// theme's background colour is used instead.
    public var codeBlockBackground: ColorToken?

    /// Corner radius for fenced code blocks, in pixels.
    public var codeBlockRadius: Double

    /// Creates a content style with the given values.
    ///
    /// All parameters have sensible defaults that reference semantic theme tokens.
    ///
    /// - Parameters:
    ///   - inlineCodeBackground: Background for inline code. Defaults to `.border`.
    ///   - inlineCodeBorderColor: Border for inline code. Defaults to `.border`.
    ///   - inlineCodeRadius: Corner radius for inline code. Defaults to `4`.
    ///   - blockquoteBorderColor: Left border for blockquotes. Defaults to `.border`.
    ///   - blockquoteBackground: Background for blockquotes. Defaults to `nil`.
    ///   - horizontalRuleColor: Colour for horizontal rules. Defaults to `.border`.
    ///   - tableBorderColor: Border for tables. Defaults to `.border`.
    ///   - tableHeaderBackground: Background for table headers. Defaults to `nil`.
    ///   - codeBlockBackground: Background for code blocks. Defaults to `nil` (uses syntax theme).
    ///   - codeBlockRadius: Corner radius for code blocks. Defaults to `6`.
    public init(
        inlineCodeBackground: ColorToken = .border,
        inlineCodeBorderColor: ColorToken? = .border,
        inlineCodeRadius: Double = 4,
        blockquoteBorderColor: ColorToken = .border,
        blockquoteBackground: ColorToken? = nil,
        horizontalRuleColor: ColorToken = .border,
        tableBorderColor: ColorToken = .border,
        tableHeaderBackground: ColorToken? = nil,
        codeBlockBackground: ColorToken? = nil,
        codeBlockRadius: Double = 6
    ) {
        self.inlineCodeBackground = inlineCodeBackground
        self.inlineCodeBorderColor = inlineCodeBorderColor
        self.inlineCodeRadius = inlineCodeRadius
        self.blockquoteBorderColor = blockquoteBorderColor
        self.blockquoteBackground = blockquoteBackground
        self.horizontalRuleColor = horizontalRuleColor
        self.tableBorderColor = tableBorderColor
        self.tableHeaderBackground = tableHeaderBackground
        self.codeBlockBackground = codeBlockBackground
        self.codeBlockRadius = codeBlockRadius
    }

    /// The default content style using semantic theme tokens.
    public static let `default` = ContentStyle()
}
