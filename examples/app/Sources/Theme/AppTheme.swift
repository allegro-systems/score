import ScoreRuntime

struct AppTheme: Theme {
    var name: String? { "app" }

    var colorRoles: [String: ColorToken] {
        [
            "surface": .oklch(0.98, 0.003, 260),
            "text": .oklch(0.13, 0.01, 260),
            "border": .oklch(0.87, 0.008, 260),
            "accent": .blue(600),
            "muted": .neutral(400),
            "destructive": .red(500),
            "success": .green(500),
        ]
    }

    var fontFamilies: [String: String] {
        [
            "body": "system-ui, -apple-system, sans-serif",
            "heading": "system-ui, -apple-system, sans-serif",
            "mono": "'SF Mono', ui-monospace, monospace",
        ]
    }

    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 8 }

    var dark: (any ThemePatch)? { AppDarkPatch() }
    var named: [String: any ThemePatch] { ["ocean": OceanPatch()] }
}

struct AppDarkPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.14, 0.01, 260),
            "text": .oklch(0.94, 0.005, 260),
            "border": .oklch(0.28, 0.01, 260),
            "accent": .blue(400),
        ]
    }
}

struct OceanPatch: ThemePatch {
    var colorRoles: [String: ColorToken]? {
        [
            "surface": .oklch(0.12, 0.03, 230),
            "text": .oklch(0.92, 0.01, 200),
            "border": .oklch(0.25, 0.03, 230),
            "accent": .cyan(400),
            "muted": .slate(400),
            "destructive": .red(400),
            "success": .emerald(400),
        ]
    }
}
