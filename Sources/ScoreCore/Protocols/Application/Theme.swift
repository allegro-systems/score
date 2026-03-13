/// A semantic or palette-based color reference used throughout Score's
/// styling system.
///
/// `ColorToken` decouples color intent from concrete color values. Renderers
/// resolve each token to the appropriate platform color at render time,
/// enabling theming, dark-mode adaptation, and design-system consistency
/// without hard-coding hex values in component code.
///
/// There are three families of tokens:
///
/// 1. **Semantic tokens** — role-based names such as `.surface`, `.text`,
///    and `.accent` whose actual values are determined by the active theme.
/// 2. **Palette tokens** — named color scales (e.g. `.blue`, `.slate`)
///    parameterized by a shade integer that typically follows a
///    Tailwind-style 50–950 range.
/// 3. **Escape hatches** — `.oklch` for precise perceptual colors and
///    `.custom` for design-system tokens not covered by the built-in palette.
///
/// ### Semantic Usage
///
/// ```swift
/// TextNode("Welcome")
///     .modifier(ForegroundColorValue(color: .text))
///
/// DivNode()
///     .modifier(BackgroundColorValue(color: .surface))
/// ```
///
/// ### Palette Usage
///
/// ```swift
/// DivNode()
///     .modifier(BackgroundColorValue(color: .blue(500)))
///     .modifier(BorderColorValue(color: .blue(700)))
/// ```
///
/// ### Custom OKLCH Color
///
/// ```swift
/// TextNode("Branded")
///     .modifier(ForegroundColorValue(color: .oklch(0.65, 0.18, 270)))
/// ```
///
/// - Note: `ColorToken` conforms to `Hashable` so tokens can be used as
///   dictionary keys in theme lookup tables, and to `Sendable` so they can
///   be safely used across concurrency boundaries.
public enum ColorToken: Sendable, Hashable {

    // MARK: - Semantic Tokens

    /// The background color of the primary surface (e.g. page or card background).
    ///
    /// Typically maps to white in light mode and a dark neutral in dark mode.
    /// Use this as the base background for containers and layout shells.
    case surface

    /// The default foreground color for body text and icons.
    ///
    /// Resolves to a high-contrast color against `.surface` to ensure
    /// readability. Prefer this over palette tokens for all readable text.
    case text

    /// The color used for dividers, input outlines, and decorative borders.
    ///
    /// Typically a low-contrast neutral that separates UI regions without
    /// drawing attention.
    case border

    /// The primary brand or interactive color used for links, buttons, and
    /// focused elements.
    ///
    /// Resolves to the active theme's primary hue. Use sparingly to draw
    /// attention to actionable elements.
    case accent

    /// A subdued foreground color for secondary text, placeholders, and
    /// supporting metadata.
    ///
    /// Lower contrast than `.text`; suitable for content that should
    /// recede visually without disappearing entirely.
    case muted

    /// A color that signals an error, danger, or irreversible action.
    ///
    /// Typically red. Use for error messages, destructive action buttons,
    /// and validation feedback.
    case destructive

    /// A color that signals a positive outcome, confirmation, or healthy
    /// status.
    ///
    /// Typically green. Use for success banners, checkmarks, and positive
    /// validation states.
    case success

    // MARK: - Palette Tokens

    /// A neutral gray shade from the neutral palette.
    ///
    /// `shade` follows a Tailwind-compatible scale where lower values
    /// (e.g. `50`, `100`) are near-white and higher values (e.g. `800`,
    /// `900`, `950`) are near-black.
    ///
    /// - Parameter shade: The shade step on the neutral scale (e.g. `100`,
    ///   `400`, `700`).
    case neutral(_ shade: Int)

    /// A blue shade from the blue palette.
    ///
    /// Suitable for informational UI, links, and focused states in contexts
    /// where the theme's `.accent` is not appropriate.
    ///
    /// - Parameter shade: The shade step on the blue scale (e.g. `100`,
    ///   `500`, `900`).
    case blue(_ shade: Int)

    /// A red shade from the red palette.
    ///
    /// Use for error states, destructive indicators, and alerts when the
    /// semantic `.destructive` token is too coarse.
    ///
    /// - Parameter shade: The shade step on the red scale (e.g. `100`,
    ///   `500`, `900`).
    case red(_ shade: Int)

    /// A green shade from the green palette.
    ///
    /// Use for success states and positive indicators when the semantic
    /// `.success` token is too coarse.
    ///
    /// - Parameter shade: The shade step on the green scale (e.g. `100`,
    ///   `500`, `900`).
    case green(_ shade: Int)

    /// An amber shade from the amber palette.
    ///
    /// Suitable for warning states, caution badges, and highlight accents
    /// with a warm yellow-orange hue.
    ///
    /// - Parameter shade: The shade step on the amber scale (e.g. `100`,
    ///   `400`, `700`).
    case amber(_ shade: Int)

    /// A sky blue shade from the sky palette.
    ///
    /// A lighter, more vibrant blue than `.blue`. Suitable for informational
    /// highlights and sky-themed illustrations.
    ///
    /// - Parameter shade: The shade step on the sky scale (e.g. `100`,
    ///   `400`, `700`).
    case sky(_ shade: Int)

    /// A slate shade from the slate palette.
    ///
    /// A cool-toned gray with a slight blue undertone. Often used for
    /// backgrounds, borders, and secondary surfaces in modern design systems.
    ///
    /// - Parameter shade: The shade step on the slate scale (e.g. `100`,
    ///   `400`, `700`).
    case slate(_ shade: Int)

    /// A cyan shade from the cyan palette.
    ///
    /// A blue-green hue suitable for data visualizations, status indicators,
    /// and decorative accents.
    ///
    /// - Parameter shade: The shade step on the cyan scale (e.g. `100`,
    ///   `400`, `700`).
    case cyan(_ shade: Int)

    /// An emerald shade from the emerald palette.
    ///
    /// A rich, saturated green suitable for success states, nature-themed
    /// illustrations, and vibrant accent colors.
    ///
    /// - Parameter shade: The shade step on the emerald scale (e.g. `100`,
    ///   `400`, `700`).
    case emerald(_ shade: Int)

    // MARK: - Escape Hatches

    /// An arbitrary color specified in the OKLCH perceptual color space.
    ///
    /// OKLCH provides perceptually uniform lightness and chroma, making it
    /// well-suited for programmatically generated colors and smooth
    /// gradients. The three components map directly to the CSS `oklch()`
    /// function.
    ///
    /// ```swift
    /// // A vivid purple: oklch(0.60, 0.22, 290)
    /// let brandPurple = ColorToken.oklch(0.60, 0.22, 290)
    /// ```
    ///
    /// - Parameters:
    ///   - lightness: Perceptual lightness in the range `0.0` (black) to `1.0` (white).
    ///   - chroma: Color saturation. `0.0` is achromatic; values above
    ///     `~0.37` may exceed the sRGB gamut.
    ///   - hue: Hue angle in degrees (`0`–`360`).
    case oklch(Double, Double, Double)

    /// A shade from a named custom color scale defined outside Score's
    /// built-in palette.
    ///
    /// Use this case to reference colors from a project-specific or
    /// third-party design token system. The renderer is responsible for
    /// resolving the `name`/`shade` pair to a concrete color value.
    ///
    /// ```swift
    /// // Reference a "brand" scale defined in the project's theme:
    /// let brandColor = ColorToken.custom("brand", shade: 600)
    /// ```
    ///
    /// - Parameters:
    ///   - name: The identifier of the custom color scale as registered
    ///     with the active theme or renderer.
    ///   - shade: The shade step within that scale (e.g. `100`, `500`, `900`).
    case custom(String, shade: Int)
}

/// A protocol that defines the theme contract for Score applications.
///
/// `Theme` captures design-system primitives at the `ScoreCore` level without
/// committing to a renderer-specific implementation. HTML/CSS modules consume
/// this contract to emit concrete style artifacts.
///
/// Typical uses include:
/// - Declaring semantic color roles and optional named scales
/// - Defining typography, spacing, and radius primitives
/// - Supplying optional dark-mode overrides through `ThemePatch`
///
/// ### Example
///
/// ```swift
/// struct AppTheme: Theme {
///     var name: String? { "default" }
///     var colorRoles: [String: ColorToken] { ["accent": .blue(600)] }
///     var customColorRoles: [String: [Int: ColorToken]] { [:] }
///     var fontFamilies: [String: String] { ["sans": "system-ui"] }
///     var typeScaleBase: Double { 16 }
///     var spacingUnit: Double { 4 }
///     var radiusBase: Double { 4 }
///     var syntaxTheme: SyntaxTheme { .rosePine }
///     var dark: (any ThemePatch)? { nil }
/// }
/// ```
///
/// ### CSS Mapping
///
/// Conforming values typically map to CSS custom properties and optional
/// `[data-theme="<name>"]` scoped overrides.
public protocol Theme: Sendable {

    /// The logical theme name.
    ///
    /// When `nil`, the renderer treats this as the unnamed default theme.
    var name: String? { get }

    /// Semantic color-role mappings.
    ///
    /// Example keys include `"surface"`, `"text"`, `"accent"`, and `"border"`.
    var colorRoles: [String: ColorToken] { get }

    /// Named color-scale mappings keyed by role then shade.
    ///
    /// Example: `"brand": [50: .custom("brand", shade: 50), 500: .custom("brand", shade: 500)]`.
    var customColorRoles: [String: [Int: ColorToken]] { get }

    /// Named font-family mappings used by typography emitters.
    ///
    /// Example keys include `"sans"`, `"mono"`, and `"brand"`.
    var fontFamilies: [String: String] { get }

    /// External stylesheet URLs imported before theme custom properties.
    ///
    /// Use this to load web fonts from any CDN (Google Fonts, Bunny Fonts,
    /// Adobe Fonts, etc.). Each URL is emitted as an `@import url(...)`
    /// rule at the top of the theme stylesheet.
    ///
    /// ```swift
    /// var fontImports: [String] {
    ///     [
    ///         "https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap",
    ///         "https://fonts.bunny.net/css?family=dm-mono:300,400,500",
    ///     ]
    /// }
    /// ```
    var fontImports: [String] { get }

    /// Local font face declarations for self-hosted fonts.
    ///
    /// Each entry generates a CSS `@font-face` rule. The ``FontFace/resource``
    /// path is resolved against the application's resources directory and
    /// fingerprinted during static site builds.
    ///
    /// ```swift
    /// var fontFaces: [FontFace] {
    ///     [
    ///         FontFace("Inter", resource: "fonts/Inter-Regular.woff2"),
    ///         FontFace("Inter", resource: "fonts/Inter-Bold.woff2", weight: .bold),
    ///     ]
    /// }
    /// ```
    var fontFaces: [FontFace] { get }

    /// The root font size in pixels used as the rem base for the type scale.
    ///
    /// Defaults to `16`. All text size variables (`--text-xs` through
    /// `--text-9xl`) are expressed in `rem` relative to this value.
    var typeScaleBase: Double { get }

    /// The spacing scale unit in points.
    var spacingUnit: Double { get }

    /// The radius scale base value in points.
    var radiusBase: Double { get }

    /// The syntax highlighting theme used for code blocks.
    ///
    /// Defaults to ``SyntaxTheme/scoreDefault``.
    var syntaxTheme: SyntaxTheme { get }

    /// Optional dark-mode patch values applied on top of the base theme.
    var dark: (any ThemePatch)? { get }

    /// Named theme variants keyed by theme name.
    ///
    /// Each entry produces a `[data-theme="<name>"]` scoped CSS block.
    /// Theme switching is handled by user-authored JavaScript that sets
    /// the `data-theme` attribute on `<html>`.
    var named: [String: any ThemePatch] { get }

    /// Styling configuration for rendered Markdown content elements.
    ///
    /// Controls how inline code, blockquotes, horizontal rules, and tables
    /// appear when rendered from Markdown. Defaults to ``ContentStyle/default``.
    var contentStyle: ContentStyle { get }

    /// Per-component CSS custom property overrides.
    ///
    /// Keys are component token names (e.g. `"card-bg"`, `"button-radius"`)
    /// and values are CSS expressions. These are emitted as
    /// `--{key}: {value}` custom properties in the `:root` block,
    /// overriding the built-in component defaults.
    ///
    /// ### Example
    ///
    /// ```swift
    /// var componentStyles: [String: String] {
    ///     [
    ///         "card-radius": "16px",
    ///         "card-shadow": "0 4px 12px oklch(0 0 0 / 0.15)",
    ///         "button-radius": "999px",  // pill buttons
    ///     ]
    /// }
    /// ```
    ///
    /// Component tokens reference base theme tokens by default (e.g.
    /// `--card-bg` defaults to `var(--color-surface)`), so changing
    /// `colorRoles["surface"]` automatically updates all components
    /// that reference it.
    var componentStyles: [String: String] { get }

}

extension Theme {

    /// Default theme name.
    public var name: String? { nil }

    /// Default color roles from ``DefaultTheme``.
    public var colorRoles: [String: ColorToken] { DefaultTheme().colorRoles }

    /// Default implementation returns an empty custom color scale map.
    public var customColorRoles: [String: [Int: ColorToken]] { [:] }

    /// Default font families from ``DefaultTheme``.
    public var fontFamilies: [String: String] { DefaultTheme().fontFamilies }

    /// Default font imports return an empty array.
    public var fontImports: [String] { [] }

    /// Default font faces return an empty array.
    public var fontFaces: [FontFace] { [] }

    /// Default type scale base from ``DefaultTheme``.
    public var typeScaleBase: Double { DefaultTheme().typeScaleBase }

    /// Default spacing unit from ``DefaultTheme``.
    public var spacingUnit: Double { DefaultTheme().spacingUnit }

    /// Default radius base from ``DefaultTheme``.
    public var radiusBase: Double { DefaultTheme().radiusBase }

    /// Default syntax theme from ``SyntaxTheme/scoreDefault``.
    public var syntaxTheme: SyntaxTheme { .scoreDefault }

    /// Default implementation returns `nil`, meaning no dark-mode patch.
    public var dark: (any ThemePatch)? { nil }

    /// Default named variants from ``DefaultTheme``.
    public var named: [String: any ThemePatch] { DefaultTheme().named }

    /// Default content style using semantic theme tokens.
    public var contentStyle: ContentStyle { .default }

    /// Default implementation returns no component style overrides.
    public var componentStyles: [String: String] { [:] }

    // MARK: - Typed Color Role Accessors

    /// The resolved surface color from the theme's color roles.
    public var surface: ColorToken { colorRoles["surface"] ?? .surface }

    /// The resolved text color from the theme's color roles.
    public var textColor: ColorToken { colorRoles["text"] ?? .text }

    /// The resolved border color from the theme's color roles.
    public var borderColor: ColorToken { colorRoles["border"] ?? .border }

    /// The resolved accent color from the theme's color roles.
    public var accentColor: ColorToken { colorRoles["accent"] ?? .accent }

    /// The resolved muted color from the theme's color roles.
    public var mutedColor: ColorToken { colorRoles["muted"] ?? .muted }

    /// The resolved destructive color from the theme's color roles.
    public var destructiveColor: ColorToken { colorRoles["destructive"] ?? .destructive }

    /// The resolved success color from the theme's color roles.
    public var successColor: ColorToken { colorRoles["success"] ?? .success }
}

/// A protocol for partial theme overrides.
///
/// `ThemePatch` mirrors `Theme` with optional fields so renderers can apply
/// targeted overrides (for example in dark mode) without redefining the entire
/// theme payload.
///
/// Typical uses include:
/// - Defining dark-mode overrides for selected semantic roles
/// - Overriding spacing/typography primitives for a variant
/// - Providing incremental patch payloads to renderer pipelines
///
/// ### Example
///
/// ```swift
/// struct DarkPatch: ThemePatch {
///     var colorRoles: [String: ColorToken]? { ["surface": .neutral(900)] }
/// }
/// ```
///
/// ### CSS Mapping
///
/// Conforming values map to partial CSS token overrides layered atop base
/// theme tokens.
public protocol ThemePatch: Sendable {

    /// Optional semantic color-role overrides.
    var colorRoles: [String: ColorToken]? { get }

    /// Optional named color-scale overrides.
    var customColorRoles: [String: [Int: ColorToken]]? { get }

    /// Optional font-family overrides.
    var fontFamilies: [String: String]? { get }

    /// Optional type-scale base override.
    var typeScaleBase: Double? { get }

    /// Optional spacing-unit override.
    var spacingUnit: Double? { get }

    /// Optional radius-base override.
    var radiusBase: Double? { get }

    /// Optional syntax theme override.
    var syntaxTheme: SyntaxTheme? { get }
}

extension ThemePatch {

    /// Default implementation returns no color-role overrides.
    public var colorRoles: [String: ColorToken]? { nil }

    /// Default implementation returns no custom color-scale overrides.
    public var customColorRoles: [String: [Int: ColorToken]]? { nil }

    /// Default implementation returns no font-family overrides.
    public var fontFamilies: [String: String]? { nil }

    /// Default implementation returns no type-scale base override.
    public var typeScaleBase: Double? { nil }

    /// Default implementation returns no spacing-unit override.
    public var spacingUnit: Double? { nil }

    /// Default implementation returns no radius-base override.
    public var radiusBase: Double? { nil }

    /// Default implementation returns no syntax-theme override.
    public var syntaxTheme: SyntaxTheme? { nil }
}
