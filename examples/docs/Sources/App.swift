import Score

@main
struct DocsApp: Application {
    var pages: [any Page] {
        [
            DocsIndex(),
            DocSection(),
        ]
    }

    var theme: (any Theme)? { DocsTheme() }
    var metadata: Metadata? {
        Metadata(
            site: "Score Docs",
            description: "Documentation for the Score Swift web framework.",
            keywords: ["score", "swift", "documentation", "web"]
        )
    }

    static func main() async throws {
        try await DocsApp().run()
    }
}

struct DocsTheme: Theme {
    var name: String? { "light" }
    var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.99, 0.005, 250),
            "text": .oklch(0.18, 0.02, 250),
            "border": .oklch(0.90, 0.01, 250),
            "accent": .oklch(0.52, 0.16, 250),
            "muted": .oklch(0.55, 0.02, 250),
            "destructive": .oklch(0.55, 0.2, 25),
            "success": .oklch(0.62, 0.17, 145),
        ]
    }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] {
        [
            "sans": "system-ui, -apple-system, sans-serif",
            "serif": "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif",
            "mono": "ui-monospace, Menlo, monospace",
        ]
    }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 8 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { DarkThemePatch() }
    var named: [String: any ThemePatch] {
        [
            "ocean": OceanThemePatch(),
            "forest": ForestThemePatch(),
        ]
    }
    var componentStyles: [String: String] { [:] }
}

struct DarkThemePatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.17, 0.02, 250),
            "text": .oklch(0.92, 0.01, 250),
            "border": .oklch(0.30, 0.02, 250),
            "accent": .oklch(0.65, 0.16, 250),
            "muted": .oklch(0.60, 0.02, 250),
        ]
    }
}

struct OceanThemePatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.15, 0.03, 230),
            "text": .oklch(0.90, 0.02, 200),
            "accent": .oklch(0.60, 0.15, 200),
        ]
    }
}

struct ForestThemePatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.15, 0.03, 140),
            "text": .oklch(0.90, 0.02, 140),
            "accent": .oklch(0.55, 0.14, 145),
        ]
    }
}
