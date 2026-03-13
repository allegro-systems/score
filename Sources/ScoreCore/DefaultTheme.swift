/// The built-in default theme shipped with Score.
///
/// `DefaultTheme` matches the Allegro handbook design system built on the
/// Allegro Pantone palette converted to OKLCH:
///
/// | Swatch       | OKLCH                    |
/// |--------------|--------------------------|
/// | Castlerock   | oklch(0.44, 0.006, 285)  |
/// | Blue Atoll   | oklch(0.68, 0.130, 215)  |
/// | Carbon       | oklch(0.22, 0.018, 240)  |
/// | Aurora       | oklch(0.88, 0.140, 98)   |
/// | Sachet Pink  | oklch(0.70, 0.130, 355)  |
///
/// Light mode is the default. Dark mode is supported in two ways:
/// - Automatically via `@media (prefers-color-scheme: dark)` using the
///   ``dark`` patch.
/// - Manually via `data-theme="dark"` using the ``named`` patch
///   dictionary, allowing user-controlled theme switching.
///
/// Applications that declare their own `theme` override this entirely.
public struct DefaultTheme: Theme, Sendable {

    public var name: String? { nil }

    public var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(1.0, 0, 0),
            "text": .oklch(0.16, 0, 0),
            "border": .oklch(0.88, 0.006, 240),
            "accent": .oklch(0.52, 0.13, 215),
            "muted": .oklch(0.50, 0, 0),
            "destructive": .oklch(0.55, 0.22, 25),
            "success": .oklch(0.60, 0.19, 145),
        ]
    }

    public var fontFamilies: [String: String] {
        [
            "sans": "'Inter', system-ui, -apple-system, sans-serif",
            "serif": "'Fraunces', serif",
            "mono": "'DM Mono', ui-monospace, monospace",
        ]
    }

    public var fontImports: [String] {
        [
            "https://fonts.googleapis.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&display=swap",
            "https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,100..900;1,9..144,100..900&display=swap",
            "https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap",
        ]
    }

    public var typeScaleBase: Double { 16 }
    public var spacingUnit: Double { 4 }
    public var radiusBase: Double { 8 }
    public var syntaxTheme: SyntaxTheme { .scoreDefault }

    public var dark: (any ThemePatch)? { DefaultDarkPatch() }

    public var named: [String: any ThemePatch] {
        ["dark": DefaultDarkPatch()]
    }

    public init() {}
}

/// The dark-mode patch for the default Allegro theme.
///
/// Dark surfaces are anchored to Carbon with Blue Atoll as the accent.
/// Overrides surface, text, border, accent, and muted color roles to
/// produce a cool dark appearance that pairs with ``DefaultTheme``.
public struct DefaultDarkPatch: ThemePatch, Sendable {

    public var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.17, 0.014, 240),
            "text": .oklch(0.93, 0.004, 240),
            "border": .oklch(0.26, 0.012, 240),
            "accent": .oklch(0.68, 0.13, 215),
            "muted": .oklch(0.58, 0.006, 240),
        ]
    }

    public init() {}
}
