import ScoreRuntime

struct AppTheme: Theme {
    var name: String? { "minimal" }

    var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.98, 0.005, 250),
            "text": .oklch(0.15, 0.01, 250),
            "border": .oklch(0.85, 0.01, 250),
            "accent": .blue(500),
            "muted": .neutral(400),
            "destructive": .red(500),
            "success": .green(500),
        ]
    }

    var fontFamilies: [String: String] {
        [
            "body": "system-ui, sans-serif",
            "heading": "system-ui, sans-serif",
            "mono": "ui-monospace, monospace",
        ]
    }

    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 8 }

    var dark: (any ThemePatch)? { DarkPatch() }
}

struct DarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.15, 0.01, 250),
            "text": .oklch(0.95, 0.005, 250),
            "border": .oklch(0.3, 0.01, 250),
        ]
    }
}
