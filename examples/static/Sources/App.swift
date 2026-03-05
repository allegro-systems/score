import Score

@main
struct StaticSite: Application {
    var pages: [any Page] {
        [
            Home(),
            About(),
            Contact(),
        ]
    }

    var theme: (any Theme)? { SiteTheme() }
    var metadata: Metadata? {
        Metadata(
            site: "Static Site",
            description: "A pure HTML/CSS site built with Score.",
            keywords: ["score", "swift", "static", "web"]
        )
    }

    static func main() async throws {
        try await StaticSite().run()
    }
}

struct SiteTheme: Theme {
    var name: String? { "default" }
    var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.99, 0.0, 0),
            "text": .oklch(0.18, 0.0, 0),
            "border": .oklch(0.90, 0.0, 0),
            "accent": .oklch(0.52, 0.16, 250),
            "muted": .oklch(0.55, 0.0, 0),
            "destructive": .oklch(0.55, 0.2, 25),
            "success": .oklch(0.62, 0.17, 145),
        ]
    }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] {
        ["sans": "system-ui, -apple-system, sans-serif", "mono": "ui-monospace, Menlo, monospace"]
    }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 8 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
    var named: [String: any ThemePatch] { [:] }
    var componentStyles: [String: String] { [:] }
}
