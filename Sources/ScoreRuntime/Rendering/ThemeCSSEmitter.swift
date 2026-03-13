import ScoreAssets
import ScoreCore

/// Emits CSS custom properties from a ``Theme`` definition.
public struct ThemeCSSEmitter: Sendable {

    private init() {}

    /// Emits a complete theme stylesheet including font imports, `@font-face`
    /// rules, `:root` block, optional dark mode media query, and named theme
    /// variants.
    ///
    /// - Parameters:
    ///   - theme: The theme to emit CSS for.
    ///   - assetManifest: An optional asset manifest used to resolve font file
    ///     paths to fingerprinted URLs. When `nil`, font resource paths are
    ///     used as-is.
    /// - Returns: The complete CSS string for the theme.
    public static func emit(
        _ theme: some Theme,
        assetManifest: AssetManifest? = nil
    ) -> String {
        var css = ""

        for url in theme.fontImports {
            css.append("@import url('\(url)');\n")
        }

        emitFontFaces(theme.fontFaces, assetManifest: assetManifest, into: &css)

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
        emitTextScale(into: &css)

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
        if let spacing = patch.spacingUnit {
            css.append("\(indent)--spacing-unit: \(cleanedPixelValue(spacing));\n")
        }
        if let radius = patch.radiusBase {
            css.append("\(indent)--radius-base: \(cleanedPixelValue(radius));\n")
        }
    }

    private static let textScale: [(name: String, rem: Double, lineHeight: String)] = [
        ("xs", 0.75, "calc(1 / 0.75)"),
        ("sm", 0.875, "calc(1.25 / 0.875)"),
        ("base", 1.0, "calc(1.5 / 1)"),
        ("lg", 1.125, "calc(1.75 / 1.125)"),
        ("xl", 1.25, "calc(1.75 / 1.25)"),
        ("2xl", 1.5, "calc(2 / 1.5)"),
        ("3xl", 1.875, "calc(2.25 / 1.875)"),
        ("4xl", 2.25, "calc(2.5 / 2.25)"),
        ("5xl", 3.0, "1"),
        ("6xl", 3.75, "1"),
        ("7xl", 4.5, "1"),
        ("8xl", 6.0, "1"),
        ("9xl", 8.0, "1"),
    ]

    private static func emitTextScale(into css: inout String, indent: String = "  ") {
        for step in textScale {
            let rem =
                step.rem.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(step.rem))" : "\(step.rem)"
            css.append("\(indent)--text-\(step.name): \(rem)rem;\n")
            css.append("\(indent)--text-\(step.name)--line-height: \(step.lineHeight);\n")
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
            emitRule(
                "a",
                declarations: ["color: var(--color-accent)", "text-decoration: none"],
                nested: [("&:hover", ["text-decoration: underline"])],
                into: &css)
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
                ],
                nested: [("code", ["background: none", "padding: 0", "border: none", "font-size: 12px"])],
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
            }\n
            """)
    }

    private static func emitContentStyles(_ theme: some Theme, into css: inout String) {
        let content = theme.contentStyle
        let syntax = theme.syntaxTheme

        var blockquoteDecls: [String] = [
            "border-left: 3px solid \(cssPropertyValue(for: content.blockquoteBorderColor))",
            "padding: 12px 20px",
            "margin: 16px 0",
        ]
        if let bg = content.blockquoteBackground {
            blockquoteDecls.append("background: \(cssPropertyValue(for: bg))")
        }
        emitRule(
            "blockquote",
            declarations: blockquoteDecls,
            nested: [("p", ["margin: 4px 0"])],
            into: &css)

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

        // Code block styles
        let codeBlockBg =
            content.codeBlockBackground
            .map { cssPropertyValue(for: $0) }
            ?? syntax.background.cssValue

        emitRule(
            "[data-code-block]",
            declarations: [
                "background: \(codeBlockBg)",
                "border-radius: \(cleanedPixelValue(content.codeBlockRadius))",
                "overflow: hidden",
                "margin: 16px 0",
            ], into: &css)

        emitRule(
            "[data-code-embedded]",
            declarations: [
                "margin: 0",
                "border-radius: 0",
            ], into: &css)

        emitRule(
            "[data-code-header]",
            declarations: [
                "display: flex",
                "align-items: center",
                "justify-content: space-between",
                "padding: 6px 16px",
                "border-bottom: 1px solid rgba(255,255,255,0.12)",
            ], into: &css)

        emitRule(
            "[data-code-label]",
            declarations: [
                "color: \(syntax.comment.cssValue)",
                "font-family: var(--font-mono, monospace)",
                "font-size: 11px",
                "text-transform: uppercase",
                "letter-spacing: 0.05em",
            ], into: &css)

        emitRule(
            "[data-code-copy]",
            declarations: [
                "background: none",
                "border: 1px solid rgba(255,255,255,0.15)",
                "color: \(syntax.variable.cssValue)",
                "font-size: 10px",
                "padding: 2px 8px",
                "border-radius: 3px",
                "cursor: pointer",
                "font-family: var(--font-mono, monospace)",
            ], into: &css)

        emitRule(
            "[data-code-source]",
            declarations: [
                "position: absolute",
                "left: -9999px",
            ], into: &css)

        emitRule(
            "[data-code-grid]",
            declarations: [
                "display: grid",
                "overflow-x: auto",
            ], into: &css)

        emitRule(
            "[data-line-numbers]",
            declarations: [
                "display: flex",
                "flex-direction: column",
                "border-right: 1px solid rgba(255,255,255,0.10)",
            ], into: &css)

        emitRule(
            "[data-line-number]",
            declarations: [
                "font-family: var(--font-mono, monospace)",
                "font-size: 13px",
                "line-height: 1.5",
                "padding: 0 12px",
                "color: \(syntax.comment.cssValue)",
                "text-align: right",
                "user-select: none",
                "-webkit-user-select: none",
            ], into: &css)

        emitRule(
            "[data-line-number]:first-child",
            declarations: ["padding-top: 12px"],
            into: &css)

        emitRule(
            "[data-line-number]:last-child",
            declarations: ["padding-bottom: 12px"],
            into: &css)

        emitRule(
            "[data-code-lines]",
            declarations: [
                "display: flex",
                "flex-direction: column",
            ], into: &css)

        emitRule(
            "[data-code-line]",
            declarations: [
                "font-family: var(--font-mono, monospace)",
                "font-size: 13px",
                "line-height: 1.5",
                "padding: 0 16px",
                "white-space: pre",
                "background: none",
                "border: none",
                "border-radius: 0",
            ], into: &css)

        emitRule(
            "[data-code-line]:first-child",
            declarations: ["padding-top: 12px"],
            into: &css)

        emitRule(
            "[data-code-line]:last-child",
            declarations: ["padding-bottom: 12px"],
            into: &css)
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

    private static func emitRule(
        _ selector: String,
        declarations: [String],
        nested: [(selector: String, declarations: [String])] = [],
        into css: inout String
    ) {
        css.append("\(selector) {\n")
        for decl in declarations {
            css.append("  \(decl);\n")
        }
        for child in nested {
            css.append("  \(child.selector) {\n")
            for decl in child.declarations {
                css.append("    \(decl);\n")
            }
            css.append("  }\n")
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

    private static func emitFontFaces(
        _ fontFaces: [FontFace],
        assetManifest: AssetManifest?,
        into css: inout String
    ) {
        for face in fontFaces {
            let resolvedPath = assetManifest?.resolve(face.resource) ?? face.resource
            let url = "/assets/\(resolvedPath)"
            let style = face.isItalic ? "italic" : "normal"

            css.append("@font-face {\n")
            css.append("  font-family: '\(face.family)';\n")

            if let format = face.cssFormat {
                css.append("  src: url('\(url)') format('\(format)');\n")
            } else {
                css.append("  src: url('\(url)');\n")
            }

            css.append("  font-weight: \(face.cssWeight);\n")
            css.append("  font-style: \(style);\n")
            css.append("  font-display: swap;\n")
            css.append("}\n")
        }
    }

}
