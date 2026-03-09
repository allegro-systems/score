import ScoreRuntime

struct BlogTheme: Theme {
    var name: String? { "blog" }

    var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.99, 0.002, 90),
            "text": .oklch(0.12, 0.01, 90),
            "border": .oklch(0.88, 0.008, 90),
            "accent": .emerald(600),
            "muted": .neutral(400),
            "destructive": .red(500),
            "success": .green(500),
        ]
    }

    var fontFamilies: [String: String] {
        [
            "body": "'Georgia', 'Times New Roman', serif",
            "heading": "system-ui, sans-serif",
            "mono": "'JetBrains Mono', ui-monospace, monospace",
        ]
    }

    var typeScaleBase: Double { 18 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }

    var dark: (any ThemePatch)? { BlogDarkPatch() }
    var named: [String: any ThemePatch] { ["one-dark": OneDarkPatch()] }
}

struct BlogDarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.13, 0.01, 90),
            "text": .oklch(0.93, 0.005, 90),
            "border": .oklch(0.28, 0.01, 90),
            "accent": .emerald(400),
        ]
    }
}

struct OneDarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.16, 0.015, 260),
            "text": .oklch(0.88, 0.01, 80),
            "border": .oklch(0.25, 0.015, 260),
            "accent": .oklch(0.70, 0.15, 200),
            "muted": .oklch(0.50, 0.02, 260),
            "destructive": .oklch(0.65, 0.2, 25),
            "success": .oklch(0.72, 0.18, 145),
        ]
    }

    var fontFamilies: [String: String]? {
        ["mono": "'Fira Code', ui-monospace, monospace"]
    }

    var syntaxThemeName: String? { "one-dark" }
}
