/// The built-in default theme shipped with Score.
///
/// `DefaultTheme` provides a complete set of design tokens based on the
/// Allegro handbook design system. It uses OKLCH colors with a cool blue
/// tint (hue 240), the handbook's font stacks, and 8 px radius.
///
/// The light palette is the base; the dark patch inverts surfaces and
/// adjusts accent lightness to match the handbook's dark mode.
///
/// Applications that declare their own `theme` override this entirely.
public struct DefaultTheme: Theme, Sendable {

    public var name: String? { nil }

    public var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(1.0, 0.0, 0),
            "text": .oklch(0.16, 0.0, 0),
            "border": .oklch(0.88, 0.006, 240),
            "accent": .oklch(0.52, 0.13, 215),
            "muted": .oklch(0.50, 0.0, 0),
            "destructive": .oklch(0.55, 0.22, 25),
            "success": .oklch(0.6, 0.19, 145),
        ]
    }

    public var customColorRoles: [String: [Int: ColorToken]] { [:] }

    public var fontFamilies: [String: String] {
        [
            "sans": "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, sans-serif",
            "serif": "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif",
            "mono": "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
        ]
    }

    public var typeScaleBase: Double { 16 }
    public var typeScaleRatio: Double { 1.25 }
    public var spacingUnit: Double { 4 }
    public var radiusBase: Double { 8 }
    public var syntaxThemeName: String? { nil }

    public var dark: (any ThemePatch)? { DefaultDarkPatch() }
    public var named: [String: any ThemePatch] { [:] }

    public init() {}
}

/// Dark-mode overrides for the default theme, matching the handbook's
/// dark palette with cool blue-tinted neutrals (hue 240).
struct DefaultDarkPatch: ThemePatch, Sendable {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.17, 0.014, 240),
            "text": .oklch(0.93, 0.004, 240),
            "border": .oklch(0.26, 0.012, 240),
            "accent": .oklch(0.68, 0.13, 215),
            "muted": .oklch(0.58, 0.006, 240),
            "destructive": .oklch(0.65, 0.2, 25),
            "success": .oklch(0.7, 0.17, 145),
        ]
    }
}
