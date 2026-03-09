import ScoreCore

/// Emits CSS custom properties from a ``Theme`` definition.
public struct ThemeCSSEmitter: Sendable {

    private init() {}

    /// Emits a complete theme stylesheet including `:root` block,
    /// optional dark mode media query, and named theme variants.
    public static func emit(_ theme: some Theme) -> String {
        var css = ":root {\n"
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

        // Box model reset
        css.append("*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n")

        // Body
        var bodyDecls: [String] = ["font-size: var(--type-scale-base)", "line-height: 1.6", "min-height: 100vh"]
        if hasColor("surface") { bodyDecls.insert("background: var(--color-surface)", at: 0) }
        if hasColor("text") { bodyDecls.insert("color: var(--color-text)", at: min(1, bodyDecls.count)) }
        if hasFont("sans") { bodyDecls.insert("font-family: var(--font-sans)", at: min(2, bodyDecls.count)) }
        css.append("body { \(bodyDecls.joined(separator: "; ")); }\n")

        // Links
        if hasColor("accent") {
            css.append("a { color: var(--color-accent); text-decoration: none; }\n")
            css.append("a:hover { text-decoration: underline; }\n")
        }

        // Headings
        var headingDecls: [String] = ["font-weight: 300"]
        if hasFont("serif") { headingDecls.insert("font-family: var(--font-serif)", at: 0) }
        if hasColor("text") { headingDecls.append("color: var(--color-text)") }
        css.append("h1, h2, h3 { \(headingDecls.joined(separator: "; ")); }\n")
        css.append("h1 { font-size: 32px; letter-spacing: -0.5px; }\n")
        css.append("h2 { font-size: 22px; }\n")
        css.append("h3 { font-size: 17px; }\n")

        // Code and preformatted
        if hasFont("mono") {
            css.append("code { font-family: var(--font-mono); font-size: 12px; }\n")
            css.append("pre { font-family: var(--font-mono); font-size: 12px; line-height: 1.7; overflow-x: auto; }\n")
            css.append("pre code { background: none; padding: 0; }\n")
        }
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
}
