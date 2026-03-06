import ScoreCore
import Testing

@testable import ScoreRuntime

struct TestTheme: Theme {
    var name: String? { "test" }
    var colorRoles: [String: ColorToken] { ["accent": .oklch(0.65, 0.18, 270)] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { ["sans": "system-ui"] }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
}

struct DarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? { ["accent": .oklch(0.8, 0.12, 270)] }
    var customColorRoles: [String: [Int: ColorToken]]? { nil }
    var fontFamilies: [String: String]? { nil }
    var typeScaleBase: Double? { nil }
    var typeScaleRatio: Double? { nil }
    var spacingUnit: Double? { nil }
    var radiusBase: Double? { nil }
    var syntaxThemeName: String? { nil }
}

struct DarkTheme: Theme {
    var name: String? { "dark" }
    var colorRoles: [String: ColorToken] { ["accent": .oklch(0.65, 0.18, 270)] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { ["sans": "system-ui"] }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { DarkPatch() }
}

struct FullDarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? { ["surface": .surface] }
    var customColorRoles: [String: [Int: ColorToken]]? { nil }
    var fontFamilies: [String: String]? { ["mono": "ui-monospace"] }
    var typeScaleBase: Double? { 18 }
    var typeScaleRatio: Double? { 1.5 }
    var spacingUnit: Double? { 6 }
    var radiusBase: Double? { 10 }
    var syntaxThemeName: String? { nil }
}

struct FullDarkTheme: Theme {
    var name: String? { "full-dark" }
    var colorRoles: [String: ColorToken] {
        [
            "neutral": .neutral(100),
            "blue": .blue(500),
            "red": .red(500),
            "green": .green(500),
            "amber": .amber(500),
            "sky": .sky(500),
            "slate": .slate(500),
            "cyan": .cyan(500),
            "emerald": .emerald(500),
            "brand": .custom("brand", shade: 600),
            "surface": .surface,
            "text": .text,
            "border": .border,
            "accent": .accent,
            "muted": .muted,
            "destructive": .destructive,
            "success": .success,
        ]
    }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { ["sans": "system-ui"] }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { FullDarkPatch() }
}

@Test func emitColorRoleCustomProperty() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(css.contains("--color-accent: oklch(0.65 0.18 270.0)"))
}

@Test func emitFontFamilyCustomProperty() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(css.contains("--font-sans: system-ui"))
}

@Test func emitTypeScaleBase() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(css.contains("--type-scale-base: 16px"))
}

@Test func emitSpacingUnit() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(css.contains("--spacing-unit: 4px"))
}

@Test func emitRadiusBase() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(css.contains("--radius-base: 4px"))
}

@Test func emitDarkModeOverrides() {
    let css = ThemeCSSEmitter.emit(DarkTheme())
    #expect(css.contains("@media (prefers-color-scheme: dark)"))
    #expect(css.contains("--color-accent: oklch(0.8 0.12 270.0)"))
}

@Test func noDarkBlockWhenNoPatch() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(!css.contains("@media (prefers-color-scheme: dark)"))
}

@Test func emitAllDarkOverridesWhenProvided() {
    let css = ThemeCSSEmitter.emit(FullDarkTheme())

    #expect(css.contains("    --color-surface: inherit;"))
    #expect(css.contains("    --font-mono: ui-monospace;"))
    #expect(css.contains("    --type-scale-base: 18px;"))
    #expect(css.contains("    --type-scale-ratio: 1.5;"))
    #expect(css.contains("    --spacing-unit: 6px;"))
    #expect(css.contains("    --radius-base: 10px;"))
}

@Test func emitSemanticAndPaletteColorTokens() {
    let css = ThemeCSSEmitter.emit(FullDarkTheme())

    #expect(css.contains("--color-neutral: var(--color-neutral-100);"))
    #expect(css.contains("--color-blue: var(--color-blue-500);"))
    #expect(css.contains("--color-red: var(--color-red-500);"))
    #expect(css.contains("--color-green: var(--color-green-500);"))
    #expect(css.contains("--color-amber: var(--color-amber-500);"))
    #expect(css.contains("--color-sky: var(--color-sky-500);"))
    #expect(css.contains("--color-slate: var(--color-slate-500);"))
    #expect(css.contains("--color-cyan: var(--color-cyan-500);"))
    #expect(css.contains("--color-emerald: var(--color-emerald-500);"))
    #expect(css.contains("--color-brand: var(--color-brand-600);"))
    #expect(css.contains("--color-surface: inherit;"))
    #expect(css.contains("--color-text: inherit;"))
    #expect(css.contains("--color-border: inherit;"))
    #expect(css.contains("--color-accent: inherit;"))
    #expect(css.contains("--color-muted: inherit;"))
    #expect(css.contains("--color-destructive: inherit;"))
    #expect(css.contains("--color-success: inherit;"))
}

private struct OceanPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? { ["accent": .oklch(0.6, 0.15, 220)] }
    var customColorRoles: [String: [Int: ColorToken]]? { nil }
    var fontFamilies: [String: String]? { nil }
    var typeScaleBase: Double? { nil }
    var typeScaleRatio: Double? { nil }
    var spacingUnit: Double? { nil }
    var radiusBase: Double? { nil }
    var syntaxThemeName: String? { nil }
}

private struct ForestPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? { ["accent": .oklch(0.55, 0.18, 145)] }
    var customColorRoles: [String: [Int: ColorToken]]? { nil }
    var fontFamilies: [String: String]? { ["sans": "Georgia, serif"] }
    var typeScaleBase: Double? { nil }
    var typeScaleRatio: Double? { nil }
    var spacingUnit: Double? { 6 }
    var radiusBase: Double? { nil }
    var syntaxThemeName: String? { nil }
}

private struct NamedTheme: Theme {
    var name: String? { "base" }
    var colorRoles: [String: ColorToken] { ["accent": .oklch(0.65, 0.18, 270)] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { ["sans": "system-ui"] }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
    var named: [String: any ThemePatch] {
        ["ocean": OceanPatch(), "forest": ForestPatch()]
    }
}

@Test func emitNamedThemeBlock() {
    let css = ThemeCSSEmitter.emit(NamedTheme())
    #expect(css.contains("[data-theme=\"ocean\"]"))
    #expect(css.contains("--color-accent: oklch(0.6 0.15 220.0)"))
}

@Test func emitMultipleNamedThemeBlocks() {
    let css = ThemeCSSEmitter.emit(NamedTheme())
    #expect(css.contains("[data-theme=\"ocean\"]"))
    #expect(css.contains("[data-theme=\"forest\"]"))
}

@Test func namedThemeIncludesFontAndSpacingOverrides() {
    let css = ThemeCSSEmitter.emit(NamedTheme())
    #expect(css.contains("--font-sans: Georgia, serif"))
    #expect(css.contains("--spacing-unit: 6px"))
}

@Test func noNamedThemeBlocksWhenEmpty() {
    let css = ThemeCSSEmitter.emit(TestTheme())
    #expect(!css.contains("[data-theme="))
}

@Test func defaultThemeProducesValidCSS() {
    let css = ThemeCSSEmitter.emit(DefaultTheme())
    #expect(css.contains(":root {"))
    #expect(css.contains("--color-surface:"))
    #expect(css.contains("--color-text:"))
    #expect(css.contains("--color-accent:"))
    #expect(css.contains("--font-sans:"))
    #expect(css.contains("@media (prefers-color-scheme: dark)"))
}
