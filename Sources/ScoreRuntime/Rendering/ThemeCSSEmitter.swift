import ScoreCore

/// Emits CSS custom properties from a ``Theme`` definition.
public struct ThemeCSSEmitter: Sendable {

    private init() {}

    /// Emits a complete theme stylesheet including font imports, `:root`
    /// block, optional dark mode media query, and named theme variants.
    public static func emit(_ theme: some Theme) -> String {
        var css = ""

        // Emit Google Fonts imports for named font families
        let imports = extractGoogleFontImports(from: theme.fontFamilies)
        for url in imports {
            css.append("@import url('\(url)');\n")
        }

        css.append(":root {\n")
        emitProperties(theme, into: &css)
        css.append("}\n")

        // Dark mode
        if let dark = theme.dark {
            css.append("@media (prefers-color-scheme: dark) {\n  :root {\n")
            emitPatchProperties(dark, into: &css)
            css.append("  }\n}\n")
        }

        // Named variants
        for (name, patch) in theme.named.sorted(by: { $0.key < $1.key }) {
            css.append("[data-theme=\"\(name)\"] {\n")
            emitPatchProperties(patch, into: &css, indent: "  ")
            css.append("}\n")
        }

        // Base element styles
        emitBaseStyles(theme, into: &css)

        return css
    }

    private static func emitProperties(_ theme: some Theme, into css: inout String) {
        // Color roles
        for (role, token) in theme.colorRoles.sorted(by: { $0.key < $1.key }) {
            css.append("  --color-\(role): \(cssValue(for: token));\n")
        }

        // Font families
        for (name, family) in theme.fontFamilies.sorted(by: { $0.key < $1.key }) {
            css.append("  --font-\(name): \(family);\n")
        }

        // Typography scale
        css.append("  --type-scale-base: \(cleanedPixelValue(theme.typeScaleBase));\n")
        css.append("  --type-scale-ratio: \(cleanedNumber(theme.typeScaleRatio));\n")

        // Spacing and radius
        css.append("  --spacing-unit: \(cleanedPixelValue(theme.spacingUnit));\n")
        css.append("  --radius-base: \(cleanedPixelValue(theme.radiusBase));\n")

        // Component styles
        for (key, value) in theme.componentStyles.sorted(by: { $0.key < $1.key }) {
            css.append("  --\(key): \(value);\n")
        }
    }

    private static func emitPatchProperties(
        _ patch: some ThemePatch,
        into css: inout String,
        indent: String = "    "
    ) {
        if let colors = patch.colorRoles {
            for (role, token) in colors.sorted(by: { $0.key < $1.key }) {
                css.append("\(indent)--color-\(role): \(cssValue(for: token));\n")
            }
        }
        if let fonts = patch.fontFamilies {
            for (name, family) in fonts.sorted(by: { $0.key < $1.key }) {
                css.append("\(indent)--font-\(name): \(family);\n")
            }
        }
        if let base = patch.typeScaleBase {
            css.append("\(indent)--type-scale-base: \(cleanedPixelValue(base));\n")
        }
        if let ratio = patch.typeScaleRatio {
            css.append("\(indent)--type-scale-ratio: \(cleanedNumber(ratio));\n")
        }
        if let spacing = patch.spacingUnit {
            css.append("\(indent)--spacing-unit: \(cleanedPixelValue(spacing));\n")
        }
        if let radius = patch.radiusBase {
            css.append("\(indent)--radius-base: \(cleanedPixelValue(radius));\n")
        }
    }

    private static func cssValue(for token: ColorToken) -> String {
        switch token {
        case .oklch(let l, let c, let h):
            return "oklch(\(cleanedNumber(l)) \(cleanedNumber(c)) \(cleanedNumber(h)))"
        case .surface: return "inherit"
        case .text: return "inherit"
        case .border: return "inherit"
        case .accent: return "inherit"
        case .muted: return "inherit"
        case .destructive: return "inherit"
        case .success: return "inherit"
        case .neutral(let shade): return "var(--color-neutral-\(shade))"
        case .blue(let shade): return "var(--color-blue-\(shade))"
        case .red(let shade): return "var(--color-red-\(shade))"
        case .green(let shade): return "var(--color-green-\(shade))"
        case .amber(let shade): return "var(--color-amber-\(shade))"
        case .sky(let shade): return "var(--color-sky-\(shade))"
        case .slate(let shade): return "var(--color-slate-\(shade))"
        case .cyan(let shade): return "var(--color-cyan-\(shade))"
        case .emerald(let shade): return "var(--color-emerald-\(shade))"
        case .custom(let name, let shade): return "var(--color-\(name)-\(shade))"
        }
    }

    private static func emitBaseStyles(_ theme: some Theme, into css: inout String) {
        let hasColor = { (role: String) in theme.colorRoles[role] != nil }
        let hasFont = { (name: String) in theme.fontFamilies[name] != nil }

        css.append(
            """
            *, *::before, *::after {
              box-sizing: border-box;
              margin: 0;
              padding: 0;
            }
            ul, ol {
              padding-left: 1.5em;
            }\n
            """)

        var bodyDecls: [String] = [
            "font-size: var(--type-scale-base)",
            "line-height: 1.6",
            "min-height: 100vh",
        ]
        if hasColor("surface") { bodyDecls.insert("background: var(--color-surface)", at: 0) }
        if hasColor("text") { bodyDecls.insert("color: var(--color-text)", at: min(1, bodyDecls.count)) }
        if hasFont("sans") { bodyDecls.insert("font-family: var(--font-sans)", at: min(2, bodyDecls.count)) }
        emitRule("body", declarations: bodyDecls, into: &css)

        if hasColor("accent") {
            emitRule("a", declarations: ["color: var(--color-accent)", "text-decoration: none"], into: &css)
            emitRule("a:hover", declarations: ["text-decoration: underline"], into: &css)
        }

        emitRule(
            ":focus-visible",
            declarations: [
                "outline: 2px solid var(--color-accent, currentColor)",
                "outline-offset: 2px",
            ], into: &css)
        emitRule(":focus:not(:focus-visible)", declarations: ["outline: none"], into: &css)

        var headingDecls: [String] = ["font-weight: 300"]
        if hasFont("serif") { headingDecls.insert("font-family: var(--font-serif)", at: 0) }
        if hasColor("text") { headingDecls.append("color: var(--color-text)") }
        emitRule("h1, h2, h3", declarations: headingDecls, into: &css)
        emitRule("h1", declarations: ["font-size: 32px", "letter-spacing: -0.5px"], into: &css)
        emitRule("h2", declarations: ["font-size: 22px", "margin-top: 40px", "margin-bottom: 16px"], into: &css)
        emitRule("h3", declarations: ["font-size: 17px", "margin-top: 32px", "margin-bottom: 12px"], into: &css)

        emitRule("p", declarations: ["margin-top: 8px", "margin-bottom: 8px"], into: &css)

        if hasFont("mono") {
            let content = theme.contentStyle
            var codeDecls: [String] = [
                "font-family: var(--font-mono)", "font-size: 0.85em",
                "background: \(cssPropertyValue(for: content.inlineCodeBackground))",
                "padding: 2px 6px",
                "border-radius: \(cleanedPixelValue(content.inlineCodeRadius))",
            ]
            if let border = content.inlineCodeBorderColor {
                codeDecls.append("border: 1px solid \(cssPropertyValue(for: border))")
            }
            emitRule("code", declarations: codeDecls, into: &css)
            emitRule(
                "pre",
                declarations: [
                    "font-family: var(--font-mono)", "font-size: 12px",
                    "line-height: 1.7", "overflow-x: auto",
                ], into: &css)
            emitRule(
                "pre code",
                declarations: ["background: none", "padding: 0", "border: none", "font-size: 12px"],
                into: &css)
        }

        emitContentStyles(theme, into: &css)

        // Responsive breakpoints
        css.append(
            """
            @media (max-width: 768px) {
              h1 { font-size: 24px; }
              h2 { font-size: 18px; }
              h3 { font-size: 15px; }
              main { padding-inline: 16px; }
              [data-sidebar-layout] { flex-direction: column; }
              [data-sidebar] {
                width: 100%;
                position: static;
                border-right: none;
                border-bottom: 1px solid var(--color-border, #333);
                padding-right: 0;
                padding-bottom: 16px;
                margin-bottom: 16px;
              }
              [data-sidebar] + article { padding-left: 0; }
            }\n
            """)
    }

    private static func emitContentStyles(_ theme: some Theme, into css: inout String) {
        let content = theme.contentStyle

        var blockquoteDecls: [String] = [
            "border-left: 3px solid \(cssPropertyValue(for: content.blockquoteBorderColor))",
            "padding: 12px 20px",
            "margin: 16px 0",
        ]
        if let bg = content.blockquoteBackground {
            blockquoteDecls.append("background: \(cssPropertyValue(for: bg))")
        }
        emitRule("blockquote", declarations: blockquoteDecls, into: &css)
        emitRule("blockquote p", declarations: ["margin: 4px 0"], into: &css)

        emitRule(
            "hr",
            declarations: [
                "border: none",
                "border-top: 1px solid \(cssPropertyValue(for: content.horizontalRuleColor))",
                "margin: 24px 0",
            ], into: &css)

        emitRule("table", declarations: ["border-collapse: collapse", "width: 100%", "margin: 16px 0"], into: &css)
        emitRule(
            "th, td",
            declarations: [
                "border: 1px solid \(cssPropertyValue(for: content.tableBorderColor))",
                "padding: 8px 12px",
                "text-align: left",
            ], into: &css)
        if let headerBg = content.tableHeaderBackground {
            emitRule("th", declarations: ["background: \(cssPropertyValue(for: headerBg))"], into: &css)
        }
    }

    private static func cssPropertyValue(for token: ColorToken) -> String {
        switch token {
        case .surface: return "var(--color-surface)"
        case .text: return "var(--color-text)"
        case .border: return "var(--color-border)"
        case .accent: return "var(--color-accent)"
        case .muted: return "var(--color-muted)"
        case .destructive: return "var(--color-destructive)"
        case .success: return "var(--color-success)"
        default: return cssValue(for: token)
        }
    }

    private static func emitRule(_ selector: String, declarations: [String], into css: inout String) {
        css.append("\(selector) {\n")
        for decl in declarations {
            css.append("  \(decl);\n")
        }
        css.append("}\n")
    }

    private static func cleanedPixelValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))px"
            : "\(value)px"
    }

    private static func cleanedNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : "\(value)"
    }

    /// Known Google Fonts and their import URL patterns.
    private static let googleFonts: [String: String] = [
        "DM Mono": "https://fonts.googleapis.com/css2?family=DM+Mono:ital,wght@0,300;0,400;0,500;1,300;1,400;1,500&display=swap",
        "Fraunces": "https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,100..900;1,9..144,100..900&display=swap",
        "Inter": "https://fonts.googleapis.com/css2?family=Inter:wght@100..900&display=swap",
        "JetBrains Mono": "https://fonts.googleapis.com/css2?family=JetBrains+Mono:ital,wght@0,100..800;1,100..800&display=swap",
        "Source Code Pro": "https://fonts.googleapis.com/css2?family=Source+Code+Pro:ital,wght@0,200..900;1,200..900&display=swap",
    ]

    /// Extracts Google Fonts import URLs from a font family map.
    ///
    /// Scans each font family string for known Google Font names and
    /// returns deduplicated import URLs.
    static func extractGoogleFontImports(
        from families: [String: String]
    ) -> [String] {
        var seen: Set<String> = []
        var urls: [String] = []
        for (_, familyValue) in families.sorted(by: { $0.key < $1.key }) {
            for (fontName, url) in googleFonts {
                if familyValue.contains(fontName) && !seen.contains(fontName) {
                    seen.insert(fontName)
                    urls.append(url)
                }
            }
        }
        return urls.sorted()
    }
}
