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
/// 3. **Named tokens** — project-specific colors defined in the theme's
///    ``Theme/colorRoles`` and referenced by name (e.g. `.brand`).
///
/// Because `ColorToken` is a struct, projects can extend it with custom
/// static properties that map directly to theme color roles:
///
/// ```swift
/// extension ColorToken {
///     static let brand = ColorToken("brand")
/// }
/// ```
///
/// - Note: `ColorToken` conforms to `Hashable` so tokens can be used as
///   dictionary keys in theme lookup tables, and to `Sendable` so they can
///   be safely used across concurrency boundaries.
public struct ColorToken: Sendable, Hashable {

    /// The internal representation of a color token.
    package enum Kind: Sendable, Hashable {
        case semantic(String)
        case palette(String, Int)
        case oklch(Double, Double, Double)
        case named(String)
    }

    /// The backing storage for this token.
    package let kind: Kind

    /// Creates a named color token that references a color role defined
    /// in the active theme.
    ///
    /// Use this initializer to define project-specific color tokens as
    /// static properties on `ColorToken`:
    ///
    /// ```swift
    /// extension ColorToken {
    ///     static let brand = ColorToken("brand")
    /// }
    /// ```
    ///
    /// - Parameter name: The color role key as defined in ``Theme/colorRoles``.
    public init(_ name: String) {
        self.kind = .named(name)
    }

    package init(kind: Kind) {
        self.kind = kind
    }

    /// The background color of the primary surface.
    public static let surface = ColorToken(kind: .semantic("surface"))

    /// The default foreground color for body text and icons.
    public static let text = ColorToken(kind: .semantic("text"))

    /// The color used for dividers, input outlines, and decorative borders.
    public static let border = ColorToken(kind: .semantic("border"))

    /// The primary brand or interactive color.
    public static let accent = ColorToken(kind: .semantic("accent"))

    /// A subdued foreground color for secondary text and placeholders.
    public static let muted = ColorToken(kind: .semantic("muted"))

    /// A color that signals an error, danger, or irreversible action.
    public static let destructive = ColorToken(kind: .semantic("destructive"))

    /// A color that signals a positive outcome or healthy status.
    public static let success = ColorToken(kind: .semantic("success"))

    /// A neutral gray shade from the neutral palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the neutral palette at the given shade.
    public static func neutral(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("neutral", shade))
    }

    /// A blue shade from the blue palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `500`, `900`).
    /// - Returns: A color token referencing the blue palette at the given shade.
    public static func blue(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("blue", shade))
    }

    /// A red shade from the red palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `500`, `900`).
    /// - Returns: A color token referencing the red palette at the given shade.
    public static func red(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("red", shade))
    }

    /// A green shade from the green palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `500`, `900`).
    /// - Returns: A color token referencing the green palette at the given shade.
    public static func green(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("green", shade))
    }

    /// An amber shade from the amber palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the amber palette at the given shade.
    public static func amber(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("amber", shade))
    }

    /// A sky blue shade from the sky palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the sky palette at the given shade.
    public static func sky(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("sky", shade))
    }

    /// A slate shade from the slate palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the slate palette at the given shade.
    public static func slate(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("slate", shade))
    }

    /// A cyan shade from the cyan palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the cyan palette at the given shade.
    public static func cyan(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("cyan", shade))
    }

    /// An emerald shade from the emerald palette.
    ///
    /// - Parameter shade: The shade step (e.g. `100`, `400`, `700`).
    /// - Returns: A color token referencing the emerald palette at the given shade.
    public static func emerald(_ shade: Int) -> ColorToken {
        ColorToken(kind: .palette("emerald", shade))
    }

    /// An arbitrary color in the OKLCH perceptual color space.
    ///
    /// - Parameters:
    ///   - lightness: Perceptual lightness (`0.0`–`1.0`).
    ///   - chroma: Color saturation (`0.0` is achromatic).
    ///   - hue: Hue angle in degrees (`0`–`360`).
    /// - Returns: A color token with the specified OKLCH values.
    public static func oklch(_ lightness: Double, _ chroma: Double, _ hue: Double) -> ColorToken {
        ColorToken(kind: .oklch(lightness, chroma, hue))
    }

}

/// Generates static `ColorToken` properties for each name.
///
/// Use inside an `extension ColorToken` block to avoid manually writing
/// `static let x = ColorToken("x")` for every custom color role.
///
/// ```swift
/// extension ColorToken {
///     #colorTokens("bg", "score", "stage")
/// }
/// ```
@freestanding(declaration, names: arbitrary)
public macro colorTokens(_ names: String...) = #externalMacro(module: "ScoreMacros", type: "ColorTokensMacro")

/// Marks a struct as a Score theme.
///
/// `@Theme` adds `Theme` protocol conformance. The `score dev` and
/// `score build` commands auto-generate `ColorToken` static properties
/// for any custom keys found in `extraColorRoles` (or `colorRoles`),
/// so no manual `#colorTokens(...)` extension is needed.
///
/// Built-in semantic tokens (`surface`, `text`, `border`, `accent`,
/// `muted`, `destructive`, `success`) are skipped since they already
/// exist on `ColorToken`.
///
/// ```swift
/// @Theme
/// struct AppTheme {
///     var extraColorRoles: [String: ColorToken] {
///         ["elevated": .oklch(0.96, 0.004, 240)]
///     }
/// }
/// // score dev/build auto-generates:
/// // extension ColorToken { public static let elevated = ColorToken("elevated") }
/// ```
@attached(extension, conformances: Theme)
public macro Theme() = #externalMacro(module: "ScoreMacros", type: "ThemeMacro")

extension ColorToken: DevDescribable {
    public var devDescription: String {
        switch kind {
        case .semantic(let name): return ".\(name)"
        case .named(let name): return ".\(name)"
        case .palette(let name, let shade): return ".\(name)(\(shade))"
        case .oklch(let l, let c, let h): return ".oklch(\(l), \(c), \(h))"
        }
    }
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
///     var colorRoles: [String: ColorToken] {
///         ["accent": .blue(600), "brand": .oklch(0.60, 0.20, 30)]
///     }
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

    /// Color-role mappings emitted as CSS custom properties.
    ///
    /// Includes both semantic roles (`"surface"`, `"text"`, `"accent"`) and
    /// project-specific custom colors (`"brand"`, `"sidebar"`). Each entry
    /// is emitted as `--color-{key}: {value}` in the `:root` block.
    ///
    /// Override this to replace the entire color role dictionary (advanced).
    /// For most apps, override ``extraColorRoles`` instead to add or override
    /// individual roles while keeping the ``DefaultTheme`` base.
    ///
    /// Reference custom entries elsewhere using ``ColorToken/init(_:)``.
    var colorRoles: [String: ColorToken] { get }

    /// Additional color roles merged on top of the ``DefaultTheme`` base.
    ///
    /// Override this instead of ``colorRoles`` to add custom colors or
    /// override individual defaults without replacing the entire dictionary:
    ///
    /// ```swift
    /// var extraColorRoles: [String: ColorToken] {
    ///     ["elevated": .oklch(0.96, 0.004, 240)]
    /// }
    /// ```
    var extraColorRoles: [String: ColorToken] { get }

    /// Named font-family mappings used by typography emitters.
    ///
    /// Override this to replace the entire font family dictionary (advanced).
    /// For most apps, override ``extraFontFamilies`` instead to add fonts
    /// while keeping the ``DefaultTheme`` base.
    ///
    /// Example keys include `"sans"`, `"mono"`, and `"brand"`.
    var fontFamilies: [String: String] { get }

    /// Additional font families merged on top of the ``DefaultTheme`` base.
    ///
    /// Override this instead of ``fontFamilies`` to add custom font families
    /// or override individual defaults without replacing the entire dictionary:
    ///
    /// ```swift
    /// var extraFontFamilies: [String: String] {
    ///     ["brand": "'Inter', system-ui, sans-serif"]
    /// }
    /// ```
    var extraFontFamilies: [String: String] { get }

    /// External stylesheet URLs imported before theme custom properties.
    ///
    /// Use this to load web fonts, icon libraries, or any external CSS.
    /// Each URL is emitted as an `@import url(...)` rule at the top of
    /// the theme stylesheet.
    ///
    /// ```swift
    /// var stylesheetImports: [String] {
    ///     [
    ///         "https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap",
    ///         "https://fonts.bunny.net/css?family=dm-mono:300,400,500",
    ///     ]
    /// }
    /// ```
    var stylesheetImports: [String] { get }

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

    /// Whether the browser's View Transitions API is enabled for
    /// same-document navigations.
    ///
    /// When `true` (the default), the assembler emits a
    /// `<meta name="view-transition" content="same-origin">` tag in
    /// `<head>`, enabling automatic cross-fade transitions between pages
    /// on supporting browsers.
    ///
    /// Set to `false` to opt out of view transitions entirely.
    ///
    /// ```swift
    /// var viewTransitions: Bool { false }
    /// ```
    var viewTransitions: Bool { get }

}

extension Theme {

    /// Default theme name.
    public var name: String? { nil }

    /// Default color roles: ``DefaultTheme`` base merged with ``extraColorRoles``.
    public var colorRoles: [String: ColorToken] {
        DefaultTheme().colorRoles.merging(extraColorRoles) { _, new in new }
    }

    /// Default extra color roles is empty.
    public var extraColorRoles: [String: ColorToken] { [:] }

    /// Default font families: ``DefaultTheme`` base merged with ``extraFontFamilies``.
    public var fontFamilies: [String: String] {
        DefaultTheme().fontFamilies.merging(extraFontFamilies) { _, new in new }
    }

    /// Default extra font families is empty.
    public var extraFontFamilies: [String: String] { [:] }

    /// Default stylesheet imports return an empty array.
    public var stylesheetImports: [String] { [] }

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

    /// View transitions are enabled by default.
    public var viewTransitions: Bool { true }

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

    /// Optional color-role overrides.
    var colorRoles: [String: ColorToken]? { get }

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
