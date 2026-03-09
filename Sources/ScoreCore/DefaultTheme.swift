/// The built-in default theme shipped with Score.
///
/// `DefaultTheme` matches the Allegro handbook design system: a dark,
/// warm-toned palette with OKLCH colors, DM Mono body text, Fraunces
/// serif headings, and tight 4 px spacing/radius scales.
///
/// Applications that declare their own `theme` override this entirely.
public struct DefaultTheme: Theme, Sendable {

    public var name: String? { nil }

    public var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.07, 0.01, 60),
            "text": .oklch(0.90, 0.02, 75),
            "border": .oklch(0.22, 0.02, 60),
            "accent": .oklch(0.73, 0.10, 75),
            "muted": .oklch(0.50, 0.03, 60),
            "destructive": .oklch(0.55, 0.22, 25),
            "success": .oklch(0.60, 0.19, 145),
        ]
    }

    public var fontFamilies: [String: String] {
        [
            "sans": "'DM Mono', ui-monospace, monospace",
            "serif": "'Fraunces', serif",
            "mono": "'DM Mono', ui-monospace, monospace",
        ]
    }

    public var typeScaleBase: Double { 16 }
    public var typeScaleRatio: Double { 1.25 }
    public var spacingUnit: Double { 4 }
    public var radiusBase: Double { 4 }

    public init() {}
}
