import ScoreCSS
import ScoreCore

/// Converts a ``Theme`` and its variants into CSS custom property declarations.
///
/// The emitter produces a `:root` block containing design-token custom
/// properties derived from the theme's color roles, font families, type
/// scale, spacing, and radius values. When the theme provides a `dark`
/// patch, a `@media (prefers-color-scheme: dark)` block is emitted.
/// Named theme variants produce `[data-theme="<name>"]` scoped blocks.
///
/// ### Example
///
/// ```swift
/// let css = ThemeCSSEmitter.emit(theme)
/// // :root {
/// //   --color-surface: oklch(0.99 0.0 0);
/// //   --font-sans: system-ui;
/// //   --type-scale-base: 16px;
/// //   --spacing-unit: 4px;
/// //   --radius-base: 4px;
/// // }
/// //
/// // [data-theme="ocean"] {
/// //   --color-accent: oklch(0.6 0.15 220);
/// // }
/// ```
public struct ThemeCSSEmitter: Sendable {

    private init() {}

    /// Emits CSS custom properties for the given theme.
    ///
    /// - Parameter theme: The theme to convert to CSS custom properties.
    /// - Returns: A CSS string containing `:root` declarations, an optional
    ///   dark-mode `@media` block, and `[data-theme]` blocks for named variants.
    public static func emit(_ theme: some Theme) -> String {
        var output = ":root {\n"
        appendColorRoles(theme.colorRoles, to: &output)
        appendFontFamilies(theme.fontFamilies, to: &output)
        output.append("  --type-scale-base: \(theme.typeScaleBase.cssLength);\n")
        output.append("  --type-scale-ratio: \(theme.typeScaleRatio.trimmed);\n")
        output.append("  --spacing-unit: \(theme.spacingUnit.cssLength);\n")
        output.append("  --radius-base: \(theme.radiusBase.cssLength);\n")
        appendComponentTokens(theme: theme, to: &output)
        output.append("}\n")

        if let dark = theme.dark {
            output.append("@media (prefers-color-scheme: dark) {\n")
            output.append("  :root {\n")
            appendPatch(dark, to: &output, indent: "    ")
            output.append("  }\n")
            output.append("}\n")
        }

        for name in theme.named.keys.sorted() {
            guard let patch = theme.named[name] else { continue }
            output.append("[data-theme=\"\(name)\"] {\n")
            appendPatch(patch, to: &output, indent: "  ")
            output.append("}\n")
        }

        return output
    }

    private static func appendPatch(
        _ patch: some ThemePatch,
        to output: inout String,
        indent: String
    ) {
        if let roles = patch.colorRoles {
            appendColorRoles(roles, to: &output, indent: indent)
        }
        if let fonts = patch.fontFamilies {
            appendFontFamilies(fonts, to: &output, indent: indent)
        }
        if let base = patch.typeScaleBase {
            output.append("\(indent)--type-scale-base: \(base.cssLength);\n")
        }
        if let ratio = patch.typeScaleRatio {
            output.append("\(indent)--type-scale-ratio: \(ratio.trimmed);\n")
        }
        if let spacing = patch.spacingUnit {
            output.append("\(indent)--spacing-unit: \(spacing.cssLength);\n")
        }
        if let radius = patch.radiusBase {
            output.append("\(indent)--radius-base: \(radius.cssLength);\n")
        }
    }

    // MARK: - Component Tokens

    /// Built-in component token defaults that reference base theme tokens.
    ///
    /// These define sensible defaults for every ScoreUI component. Users
    /// can override individual tokens via `Theme.componentStyles`.
    /// All values reference base theme custom properties so they
    /// automatically update when the theme changes.
    private static let defaultComponentTokens: [String: String] = {
        var tokens: [String: String] = [:]
        for group in componentTokenGroups {
            tokens.merge(group) { _, new in new }
        }
        return tokens
    }()

    private static let cardTokens: [String: String] = [
        "card-bg": "var(--color-surface)",
        "card-fg": "var(--color-text)",
        "card-border": "var(--color-border)",
        "card-radius": "var(--radius-base)",
        "card-padding": "calc(var(--spacing-unit) * 6)",
        "card-shadow": "0 1px 3px 0 oklch(0 0 0 / 0.1), 0 1px 2px -1px oklch(0 0 0 / 0.1)",
    ]

    private static let navBarTokens: [String: String] = [
        "navbar-bg": "var(--color-surface)",
        "navbar-fg": "var(--color-text)",
        "navbar-border": "var(--color-border)",
        "navbar-height": "calc(var(--spacing-unit) * 16)",
        "navbar-padding-x": "calc(var(--spacing-unit) * 6)",
    ]

    private static let buttonTokens: [String: String] = [
        "button-radius": "var(--radius-base)",
        "button-padding-x": "calc(var(--spacing-unit) * 4)",
        "button-padding-y": "calc(var(--spacing-unit) * 2)",
        "button-font-weight": "500",
    ]

    private static let alertTokens: [String: String] = [
        "alert-bg": "var(--color-surface)",
        "alert-fg": "var(--color-text)",
        "alert-border": "var(--color-border)",
        "alert-radius": "var(--radius-base)",
        "alert-padding": "calc(var(--spacing-unit) * 4)",
    ]

    private static let badgeTokens: [String: String] = [
        "badge-radius": "999px",
        "badge-padding-x": "calc(var(--spacing-unit) * 2.5)",
        "badge-padding-y": "calc(var(--spacing-unit) * 0.5)",
        "badge-font-size": "calc(var(--type-scale-base) * 0.75)",
        "badge-font-weight": "500",
    ]

    private static let dialogTokens: [String: String] = [
        "dialog-bg": "var(--color-surface)",
        "dialog-fg": "var(--color-text)",
        "dialog-border": "var(--color-border)",
        "dialog-radius": "calc(var(--radius-base) * 1.5)",
        "dialog-padding": "calc(var(--spacing-unit) * 6)",
        "dialog-shadow": "0 25px 50px -12px oklch(0 0 0 / 0.25)",
        "dialog-overlay": "oklch(0 0 0 / 0.5)",
    ]

    private static let sheetTokens: [String: String] = [
        "sheet-bg": "var(--color-surface)",
        "sheet-fg": "var(--color-text)",
        "sheet-border": "var(--color-border)",
    ]

    private static let accordionTokens: [String: String] = [
        "accordion-border": "var(--color-border)",
        "accordion-padding": "calc(var(--spacing-unit) * 4)",
    ]

    private static let tabsTokens: [String: String] = [
        "tabs-border": "var(--color-border)",
        "tabs-active-fg": "var(--color-text)",
        "tabs-inactive-fg": "var(--color-muted)",
    ]

    private static let toastTokens: [String: String] = [
        "toast-bg": "var(--color-surface)",
        "toast-fg": "var(--color-text)",
        "toast-border": "var(--color-border)",
        "toast-radius": "var(--radius-base)",
        "toast-padding": "calc(var(--spacing-unit) * 4)",
        "toast-shadow": "0 4px 12px oklch(0 0 0 / 0.15)",
    ]

    private static let dropdownTokens: [String: String] = [
        "dropdown-bg": "var(--color-surface)",
        "dropdown-fg": "var(--color-text)",
        "dropdown-border": "var(--color-border)",
        "dropdown-radius": "var(--radius-base)",
        "dropdown-shadow": "0 4px 6px -1px oklch(0 0 0 / 0.1)",
    ]

    private static let inputTokens: [String: String] = [
        "input-bg": "var(--color-surface)",
        "input-fg": "var(--color-text)",
        "input-border": "var(--color-border)",
        "input-radius": "var(--radius-base)",
        "input-padding-x": "calc(var(--spacing-unit) * 3)",
        "input-padding-y": "calc(var(--spacing-unit) * 2)",
        "input-focus-ring": "var(--color-accent)",
    ]

    private static let avatarTokens: [String: String] = [
        "avatar-radius": "999px",
        "avatar-bg": "var(--color-muted)",
        "avatar-size-sm": "calc(var(--spacing-unit) * 8)",
        "avatar-size-md": "calc(var(--spacing-unit) * 10)",
        "avatar-size-lg": "calc(var(--spacing-unit) * 12)",
    ]

    private static let progressTokens: [String: String] = [
        "progress-bg": "var(--color-border)",
        "progress-fill": "var(--color-accent)",
        "progress-radius": "999px",
        "progress-height": "calc(var(--spacing-unit) * 2)",
    ]

    private static let skeletonTokens: [String: String] = [
        "skeleton-bg": "var(--color-muted)",
        "skeleton-radius": "var(--radius-base)",
    ]

    private static let separatorTokens: [String: String] = [
        "separator-color": "var(--color-border)",
        "separator-thickness": "1px",
    ]

    private static let tooltipTokens: [String: String] = [
        "tooltip-bg": "var(--color-text)",
        "tooltip-fg": "var(--color-surface)",
        "tooltip-radius": "calc(var(--radius-base) * 0.5)",
        "tooltip-padding": "calc(var(--spacing-unit) * 2)",
    ]

    private static let breadcrumbTokens: [String: String] = [
        "breadcrumb-separator-color": "var(--color-muted)",
    ]

    private static let paginationTokens: [String: String] = [
        "pagination-active-bg": "var(--color-accent)",
        "pagination-active-fg": "var(--color-surface)",
        "pagination-radius": "var(--radius-base)",
    ]

    private static let commandPaletteTokens: [String: String] = [
        "command-bg": "var(--color-surface)",
        "command-fg": "var(--color-text)",
        "command-border": "var(--color-border)",
        "command-radius": "calc(var(--radius-base) * 1.5)",
        "command-shadow": "0 25px 50px -12px oklch(0 0 0 / 0.25)",
    ]

    private static let switchTokens: [String: String] = [
        "switch-bg": "var(--color-border)",
        "switch-bg-checked": "var(--color-accent)",
        "switch-thumb": "var(--color-surface)",
        "switch-radius": "999px",
    ]

    private static let editorTokens: [String: String] = [
        "editor-bg": "var(--color-surface)",
        "editor-fg": "var(--color-text)",
        "editor-border": "var(--color-border)",
        "editor-radius": "var(--radius-base)",
        "editor-line-height": "1.6",
        "editor-font-family": "var(--font-mono)",
        "editor-font-size": "14px",
        "editor-gutter-bg": "var(--color-muted)",
        "editor-gutter-fg": "var(--color-text)",
        "editor-gutter-width": "3.5em",
        "editor-cursor-color": "var(--color-text)",
        "editor-selection-bg": "oklch(0.8 0.04 240 / 0.3)",
    ]

    private static let syntaxHighlightingTokens: [String: String] = [
        "editor-keyword": "oklch(0.55 0.15 300)",
        "editor-string": "oklch(0.55 0.12 150)",
        "editor-comment": "oklch(0.6 0.02 240)",
        "editor-function": "oklch(0.55 0.14 250)",
        "editor-type": "oklch(0.55 0.12 60)",
        "editor-number": "oklch(0.55 0.15 30)",
        "editor-operator": "var(--color-text)",
        "editor-property": "oklch(0.55 0.1 200)",
    ]

    private static let editorLSPTokens: [String: String] = [
        "editor-error": "var(--color-destructive)",
        "editor-warning": "oklch(0.7 0.15 80)",
        "editor-info": "var(--color-accent)",
        "editor-autocomplete-bg": "var(--color-surface)",
        "editor-autocomplete-border": "var(--color-border)",
        "editor-autocomplete-selected": "var(--color-accent)",
        "editor-autocomplete-shadow": "0 4px 12px oklch(0 0 0 / 0.15)",
        "editor-hover-bg": "var(--color-surface)",
        "editor-hover-border": "var(--color-border)",
    ]

    private static let componentTokenGroups: [[String: String]] = [
        cardTokens, navBarTokens, buttonTokens, alertTokens, badgeTokens,
        dialogTokens, sheetTokens, accordionTokens, tabsTokens, toastTokens,
        dropdownTokens, inputTokens, avatarTokens, progressTokens, skeletonTokens,
        separatorTokens, tooltipTokens, breadcrumbTokens, paginationTokens,
        commandPaletteTokens, switchTokens, editorTokens, syntaxHighlightingTokens,
        editorLSPTokens,
    ]

    // MARK: - Component CSS Rules

    /// A CSS rule definition for data-driven component styling.
    ///
    /// Each entry maps a CSS selector to its corresponding declarations,
    /// used by ``emitComponentCSS()`` to generate the component stylesheet.
    private struct CSSRule: Sendable {
        let selector: String
        let declarations: String
    }

    /// Emits CSS rules that consume the component tokens defined in `:root`.
    ///
    /// These rules target `[data-component]` and `[data-part]` attributes
    /// so that every ScoreUI component is styled by the theme. Users can
    /// override any component token via `Theme.componentStyles` and the
    /// CSS rules automatically pick up the new values.
    ///
    /// - Returns: A CSS string with all component styling rules.
    public static func emitComponentCSS() -> String {
        var css = ""
        for group in componentCSSGroups {
            for rule in group {
                css.append("\(rule.selector) { \(rule.declarations) }\n")
            }
            css.append("\n")
        }
        return css
    }

    private static let cardCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"card\"]", declarations: "background: var(--card-bg); color: var(--card-fg); border: 1px solid var(--card-border); border-radius: var(--card-radius); box-shadow: var(--card-shadow); overflow: hidden;"),
        CSSRule(selector: "[data-component=\"card\"] [data-part=\"header\"]", declarations: "padding: var(--card-padding); padding-bottom: 0;"),
        CSSRule(selector: "[data-component=\"card\"] [data-part=\"title\"]", declarations: "font-weight: 600; line-height: 1.4;"),
        CSSRule(selector: "[data-component=\"card\"] [data-part=\"description\"]", declarations: "color: var(--color-muted); font-size: 0.875em;"),
        CSSRule(selector: "[data-component=\"card\"] [data-part=\"content\"]", declarations: "padding: var(--card-padding);"),
        CSSRule(selector: "[data-component=\"card\"] [data-part=\"footer\"]", declarations: "padding: var(--card-padding); padding-top: 0;"),
    ]

    private static let navBarCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"navbar\"]", declarations: "background: var(--navbar-bg); color: var(--navbar-fg); border-bottom: 1px solid var(--navbar-border); min-height: var(--navbar-height); padding-inline: var(--navbar-padding-x);"),
        CSSRule(selector: "[data-component=\"navbar\"] > nav", declarations: "display: flex; align-items: center; height: 100%; gap: 1rem;"),
        CSSRule(selector: "[data-component=\"navbar\"] [data-part=\"brand\"]", declarations: "font-weight: 600; text-decoration: none; color: inherit; display: flex; align-items: center; gap: 0.5rem;"),
        CSSRule(selector: "[data-component=\"navbar\"] [data-part=\"content\"]", declarations: "display: flex; list-style: none; gap: 0.25rem; margin: 0; padding: 0; flex: 1;"),
        CSSRule(selector: "[data-component=\"navbar\"] [data-part=\"content\"] a", declarations: "text-decoration: none; color: inherit; padding: 0.5rem 0.75rem; border-radius: var(--button-radius);"),
        CSSRule(selector: "[data-component=\"navbar\"] [data-part=\"content\"] [data-state=\"active\"] a", declarations: "font-weight: 600;"),
        CSSRule(selector: "[data-component=\"navbar\"] [data-part=\"actions\"]", declarations: "display: flex; align-items: center; gap: 0.5rem;"),
    ]

    private static let buttonCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"button\"]", declarations: "display: inline-flex; align-items: center; justify-content: center; border-radius: var(--button-radius); padding: var(--button-padding-y) var(--button-padding-x); font-weight: var(--button-font-weight); cursor: pointer; border: 1px solid transparent; transition: background 0.15s, border-color 0.15s, color 0.15s; line-height: 1.25;"),
        CSSRule(selector: "[data-component=\"button\"][data-variant=\"default\"]", declarations: "background: var(--color-accent); color: var(--color-surface);"),
        CSSRule(selector: "[data-component=\"button\"][data-variant=\"outline\"]", declarations: "background: transparent; color: var(--color-text); border-color: var(--color-border);"),
        CSSRule(selector: "[data-component=\"button\"][data-variant=\"ghost\"]", declarations: "background: transparent; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"button\"][data-variant=\"destructive\"]", declarations: "background: var(--color-destructive); color: var(--color-surface);"),
        CSSRule(selector: "[data-component=\"button\"][data-size=\"small\"]", declarations: "font-size: 0.875em; padding: calc(var(--button-padding-y) * 0.75) calc(var(--button-padding-x) * 0.75);"),
        CSSRule(selector: "[data-component=\"button\"][data-size=\"large\"]", declarations: "font-size: 1.125em; padding: calc(var(--button-padding-y) * 1.25) calc(var(--button-padding-x) * 1.25);"),
        CSSRule(selector: "[data-component=\"button\"]:disabled", declarations: "opacity: 0.5; cursor: not-allowed;"),
    ]

    private static let alertCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"alert\"]", declarations: "background: var(--alert-bg); color: var(--alert-fg); border: 1px solid var(--alert-border); border-radius: var(--alert-radius); padding: var(--alert-padding);"),
        CSSRule(selector: "[data-component=\"alert\"] [data-part=\"title\"]", declarations: "font-weight: 600;"),
        CSSRule(selector: "[data-component=\"alert\"] [data-part=\"description\"]", declarations: "color: var(--color-muted);"),
        CSSRule(selector: "[data-component=\"alert\"][data-variant=\"destructive\"]", declarations: "border-left: 4px solid var(--color-destructive);"),
        CSSRule(selector: "[data-component=\"alert\"][data-variant=\"success\"]", declarations: "border-left: 4px solid var(--color-success);"),
        CSSRule(selector: "[data-component=\"alert\"][data-variant=\"warning\"]", declarations: "border-left: 4px solid oklch(0.75 0.15 80);"),
        CSSRule(selector: "[data-component=\"alert\"][data-variant=\"info\"]", declarations: "border-left: 4px solid var(--color-accent);"),
    ]

    private static let badgeCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"badge\"]", declarations: "display: inline-flex; align-items: center; border-radius: var(--badge-radius); padding: var(--badge-padding-y) var(--badge-padding-x); font-size: var(--badge-font-size); font-weight: var(--badge-font-weight); line-height: 1; border: 1px solid var(--color-border);"),
        CSSRule(selector: "[data-component=\"badge\"][data-variant=\"default\"]", declarations: "background: var(--color-surface); color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"badge\"][data-variant=\"success\"]", declarations: "background: var(--color-success); color: var(--color-surface); border-color: transparent;"),
        CSSRule(selector: "[data-component=\"badge\"][data-variant=\"warning\"]", declarations: "background: oklch(0.75 0.15 80); color: oklch(0.3 0.05 80); border-color: transparent;"),
        CSSRule(selector: "[data-component=\"badge\"][data-variant=\"destructive\"]", declarations: "background: var(--color-destructive); color: var(--color-surface); border-color: transparent;"),
        CSSRule(selector: "[data-component=\"badge\"][data-variant=\"outline\"]", declarations: "background: transparent; color: var(--color-text);"),
    ]

    private static let dialogCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"dialog\"]", declarations: "background: var(--dialog-bg); color: var(--dialog-fg); border: 1px solid var(--dialog-border); border-radius: var(--dialog-radius); box-shadow: var(--dialog-shadow); max-width: 32rem; width: 100%; padding: 0;"),
        CSSRule(selector: "[data-component=\"dialog\"]::backdrop", declarations: "background: var(--dialog-overlay);"),
        CSSRule(selector: "[data-component=\"dialog\"] [data-part=\"header\"]", declarations: "padding: var(--dialog-padding); padding-bottom: 0;"),
        CSSRule(selector: "[data-component=\"dialog\"] [data-part=\"body\"]", declarations: "padding: var(--dialog-padding);"),
        CSSRule(selector: "[data-component=\"dialog\"] [data-part=\"footer\"]", declarations: "padding: var(--dialog-padding); padding-top: 0; display: flex; justify-content: flex-end; gap: 0.5rem;"),
    ]

    private static let sheetCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"sheet\"]", declarations: "background: var(--sheet-bg); color: var(--sheet-fg); border: none; padding: 0; margin: 0; max-width: none; max-height: none;"),
        CSSRule(selector: "[data-component=\"sheet\"]::backdrop", declarations: "background: var(--dialog-overlay);"),
        CSSRule(selector: "[data-component=\"sheet\"][data-side=\"right\"]", declarations: "position: fixed; inset: 0 0 0 auto; width: 24rem; border-left: 1px solid var(--sheet-border);"),
        CSSRule(selector: "[data-component=\"sheet\"][data-side=\"left\"]", declarations: "position: fixed; inset: 0 auto 0 0; width: 24rem; border-right: 1px solid var(--sheet-border);"),
        CSSRule(selector: "[data-component=\"sheet\"][data-side=\"top\"]", declarations: "position: fixed; inset: 0 0 auto 0; height: 16rem; border-bottom: 1px solid var(--sheet-border);"),
        CSSRule(selector: "[data-component=\"sheet\"][data-side=\"bottom\"]", declarations: "position: fixed; inset: auto 0 0 0; height: 16rem; border-top: 1px solid var(--sheet-border);"),
    ]

    private static let accordionCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"accordion\"]", declarations: "border: 1px solid var(--accordion-border); border-radius: var(--radius-base); overflow: hidden;"),
        CSSRule(selector: "[data-component=\"accordion\"] [data-part=\"item\"]", declarations: "border-bottom: 1px solid var(--accordion-border);"),
        CSSRule(selector: "[data-component=\"accordion\"] [data-part=\"item\"]:last-child", declarations: "border-bottom: none;"),
        CSSRule(selector: "[data-component=\"accordion\"] [data-part=\"trigger\"]", declarations: "padding: var(--accordion-padding); cursor: pointer; font-weight: 500; list-style: none; width: 100%; display: flex; justify-content: space-between; align-items: center;"),
        CSSRule(selector: "[data-component=\"accordion\"] [data-part=\"trigger\"]::-webkit-details-marker", declarations: "display: none;"),
        CSSRule(selector: "[data-component=\"accordion\"] [data-part=\"content\"]", declarations: "padding: 0 var(--accordion-padding) var(--accordion-padding);"),
    ]

    private static let tabsCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"tabs\"]", declarations: ""),
        CSSRule(selector: "[data-component=\"tabs\"] [data-part=\"trigger\"]", declarations: "padding: 0.5rem 1rem; cursor: pointer; border: none; background: transparent; font-weight: 500; color: var(--tabs-inactive-fg); border-bottom: 2px solid transparent;"),
        CSSRule(selector: "[data-component=\"tabs\"] [data-part=\"trigger\"][data-state=\"active\"]", declarations: "color: var(--tabs-active-fg); border-bottom-color: var(--color-accent);"),
        CSSRule(selector: "[data-component=\"tabs\"] [data-part=\"panel\"]", declarations: "padding: 1rem 0;"),
        CSSRule(selector: "[data-component=\"tabs\"] [data-part=\"panel\"][data-state=\"inactive\"]", declarations: "display: none;"),
    ]

    private static let toastCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"toast\"]", declarations: "background: var(--toast-bg); color: var(--toast-fg); border: 1px solid var(--toast-border); border-radius: var(--toast-radius); padding: var(--toast-padding); box-shadow: var(--toast-shadow);"),
        CSSRule(selector: "[data-component=\"toast\"] [data-part=\"title\"]", declarations: "font-weight: 600;"),
        CSSRule(selector: "[data-component=\"toast\"] [data-part=\"description\"]", declarations: "color: var(--color-muted); font-size: 0.875em;"),
        CSSRule(selector: "[data-component=\"toast\"] [data-part=\"action\"]", declarations: "font-size: 0.75em; font-weight: 500; border: 1px solid var(--color-border); border-radius: calc(var(--radius-base) * 0.5); padding: 0.25rem 0.5rem; cursor: pointer; background: transparent;"),
        CSSRule(selector: "[data-component=\"toast\"][data-variant=\"success\"]", declarations: "border-left: 4px solid var(--color-success);"),
        CSSRule(selector: "[data-component=\"toast\"][data-variant=\"error\"]", declarations: "border-left: 4px solid var(--color-destructive);"),
        CSSRule(selector: "[data-component=\"toast\"][data-variant=\"warning\"]", declarations: "border-left: 4px solid oklch(0.75 0.15 80);"),
    ]

    private static let dropdownCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"dropdown\"]", declarations: "position: relative; display: inline-block;"),
        CSSRule(selector: "[data-component=\"dropdown\"] [data-part=\"trigger\"]", declarations: "cursor: pointer; list-style: none;"),
        CSSRule(selector: "[data-component=\"dropdown\"] [data-part=\"trigger\"]::-webkit-details-marker", declarations: "display: none;"),
        CSSRule(selector: "[data-component=\"dropdown\"] [data-part=\"content\"]", declarations: "position: absolute; z-index: 50; min-width: 10rem; background: var(--dropdown-bg); color: var(--dropdown-fg); border: 1px solid var(--dropdown-border); border-radius: var(--dropdown-radius); box-shadow: var(--dropdown-shadow); padding: 0.25rem; list-style: none; margin: 0;"),
        CSSRule(selector: "[data-component=\"dropdown\"] [data-part=\"item\"]", declarations: ""),
        CSSRule(selector: "[data-component=\"dropdown\"] [data-part=\"item\"] button, [data-component=\"dropdown\"] [data-part=\"item\"] a", declarations: "display: block; width: 100%; padding: 0.5rem 0.75rem; border: none; background: transparent; text-align: start; cursor: pointer; border-radius: calc(var(--dropdown-radius) * 0.5); text-decoration: none; color: inherit;"),
    ]

    private static let inputCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"input\"]", declarations: "display: flex; flex-direction: column; gap: 0.375rem;"),
        CSSRule(selector: "[data-component=\"input\"] [data-part=\"label\"]", declarations: "font-weight: 500; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"input\"] [data-part=\"input\"]", declarations: "background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none;"),
        CSSRule(selector: "[data-component=\"input\"] [data-part=\"input\"]:focus", declarations: "border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent);"),
        CSSRule(selector: "[data-component=\"input\"][data-state=\"error\"] [data-part=\"input\"]", declarations: "border-color: var(--color-destructive);"),
        CSSRule(selector: "[data-component=\"input\"] [data-part=\"error\"]", declarations: "color: var(--color-destructive); font-size: 0.875em;"),
        CSSRule(selector: "[data-component=\"input\"] [data-part=\"helper\"]", declarations: "color: var(--color-muted); font-size: 0.875em;"),
    ]

    private static let textareaCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"textarea\"]", declarations: "display: flex; flex-direction: column; gap: 0.375rem;"),
        CSSRule(selector: "[data-component=\"textarea\"] [data-part=\"label\"]", declarations: "font-weight: 500; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"textarea\"] [data-part=\"textarea\"]", declarations: "background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none; resize: vertical;"),
        CSSRule(selector: "[data-component=\"textarea\"] [data-part=\"textarea\"]:focus", declarations: "border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent);"),
        CSSRule(selector: "[data-component=\"textarea\"][data-state=\"error\"] [data-part=\"textarea\"]", declarations: "border-color: var(--color-destructive);"),
        CSSRule(selector: "[data-component=\"textarea\"] [data-part=\"error\"]", declarations: "color: var(--color-destructive); font-size: 0.875em;"),
        CSSRule(selector: "[data-component=\"textarea\"] [data-part=\"helper\"]", declarations: "color: var(--color-muted); font-size: 0.875em;"),
    ]

    private static let selectCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"select\"]", declarations: "display: flex; flex-direction: column; gap: 0.375rem;"),
        CSSRule(selector: "[data-component=\"select\"] [data-part=\"label\"]", declarations: "font-weight: 500; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"select\"] [data-part=\"select\"]", declarations: "background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none;"),
        CSSRule(selector: "[data-component=\"select\"] [data-part=\"select\"]:focus", declarations: "border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent);"),
    ]

    private static let checkboxCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"checkbox\"]", declarations: "display: flex; align-items: center; gap: 0.5rem; cursor: pointer; padding: 0.25rem;"),
        CSSRule(selector: "[data-component=\"checkbox\"] [data-part=\"control\"]", declarations: "accent-color: var(--color-accent);"),
    ]

    private static let switchCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"switch\"]", declarations: "display: flex; align-items: center; gap: 0.5rem; cursor: pointer;"),
        CSSRule(selector: "[data-component=\"switch\"] [data-part=\"control\"]", declarations: "appearance: none; width: 2.5rem; height: 1.5rem; background: var(--switch-bg); border-radius: var(--switch-radius); position: relative; cursor: pointer; transition: background 0.2s; border: none;"),
        CSSRule(selector: "[data-component=\"switch\"] [data-part=\"control\"]:checked", declarations: "background: var(--switch-bg-checked);"),
        CSSRule(selector: "[data-component=\"switch\"] [data-part=\"control\"]::before", declarations: "content: \"\"; position: absolute; width: 1.125rem; height: 1.125rem; border-radius: 50%; background: var(--switch-thumb); top: 0.1875rem; left: 0.1875rem; transition: transform 0.2s;"),
        CSSRule(selector: "[data-component=\"switch\"] [data-part=\"control\"]:checked::before", declarations: "transform: translateX(1rem);"),
    ]

    private static let radioGroupCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"radio-group\"]", declarations: "border: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.5rem;"),
        CSSRule(selector: "[data-component=\"radio-group\"] [data-part=\"legend\"]", declarations: "font-weight: 500; color: var(--color-text); margin-bottom: 0.25rem;"),
        CSSRule(selector: "[data-component=\"radio-group\"] [data-part=\"option\"]", declarations: "display: flex; align-items: center; gap: 0.5rem; cursor: pointer;"),
        CSSRule(selector: "[data-component=\"radio-group\"] [data-part=\"control\"]", declarations: "accent-color: var(--color-accent);"),
    ]

    private static let sliderCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"slider\"]", declarations: "display: flex; flex-direction: column; gap: 0.375rem;"),
        CSSRule(selector: "[data-component=\"slider\"] [data-part=\"label\"]", declarations: "font-weight: 500; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"slider\"] [data-part=\"track\"]", declarations: "accent-color: var(--color-accent); width: 100%;"),
    ]

    private static let formLabelCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"label\"]", declarations: "font-weight: 500;"),
    ]

    private static let avatarCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"avatar\"]", declarations: "display: inline-flex; align-items: center; justify-content: center; overflow: hidden; border-radius: var(--avatar-radius); background: var(--avatar-bg);"),
        CSSRule(selector: "[data-component=\"avatar\"][data-size=\"small\"]", declarations: "width: var(--avatar-size-sm); height: var(--avatar-size-sm);"),
        CSSRule(selector: "[data-component=\"avatar\"][data-size=\"medium\"]", declarations: "width: var(--avatar-size-md); height: var(--avatar-size-md);"),
        CSSRule(selector: "[data-component=\"avatar\"][data-size=\"large\"]", declarations: "width: var(--avatar-size-lg); height: var(--avatar-size-lg);"),
        CSSRule(selector: "[data-component=\"avatar\"] [data-part=\"image\"]", declarations: "width: 100%; height: 100%; object-fit: cover;"),
        CSSRule(selector: "[data-component=\"avatar\"] [data-part=\"fallback\"]", declarations: "font-weight: 600; font-size: 0.875em;"),
    ]

    private static let progressCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"progress\"]", declarations: "display: flex; flex-direction: column; gap: 0.375rem;"),
        CSSRule(selector: "[data-component=\"progress\"] [data-part=\"label\"]", declarations: "font-weight: 500; font-size: 0.875em;"),
        CSSRule(selector: "[data-component=\"progress\"] [data-part=\"track\"]", declarations: "background: var(--progress-bg); border-radius: var(--progress-radius); height: var(--progress-height); overflow: hidden;"),
        CSSRule(selector: "[data-component=\"progress\"] [data-part=\"fill\"]", declarations: "height: 100%;"),
        CSSRule(selector: "[data-component=\"progress\"] progress", declarations: "appearance: none; width: 100%; height: 100%; border: none;"),
        CSSRule(selector: "[data-component=\"progress\"] progress::-webkit-progress-bar", declarations: "background: transparent;"),
        CSSRule(selector: "[data-component=\"progress\"] progress::-webkit-progress-value", declarations: "background: var(--progress-fill); border-radius: var(--progress-radius);"),
        CSSRule(selector: "[data-component=\"progress\"] progress::-moz-progress-bar", declarations: "background: var(--progress-fill); border-radius: var(--progress-radius);"),
    ]

    private static let skeletonCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"skeleton\"]", declarations: "background: var(--skeleton-bg); border-radius: var(--skeleton-radius); animation: score-skeleton-pulse 2s ease-in-out infinite;"),
        CSSRule(selector: "@keyframes score-skeleton-pulse", declarations: "0%, 100% { opacity: 1; } 50% { opacity: 0.5; }"),
    ]

    private static let separatorCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"separator\"]", declarations: "border: none; border-top: var(--separator-thickness) solid var(--separator-color); margin: 0;"),
        CSSRule(selector: "[data-component=\"separator\"][data-orientation=\"vertical\"]", declarations: "border-top: none; border-left: var(--separator-thickness) solid var(--separator-color); height: 100%; width: 0;"),
    ]

    private static let tooltipCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"tooltip\"]", declarations: "position: relative; display: inline-block;"),
        CSSRule(selector: "[data-component=\"tooltip\"] [data-part=\"content\"]", declarations: "display: none; position: absolute; z-index: 50; background: var(--tooltip-bg); color: var(--tooltip-fg); border-radius: var(--tooltip-radius); padding: var(--tooltip-padding); font-size: 0.875em; white-space: nowrap; pointer-events: none;"),
        CSSRule(selector: "[data-component=\"tooltip\"] [data-part=\"content\"][data-position=\"top\"]", declarations: "bottom: 100%; left: 50%; transform: translateX(-50%); margin-bottom: 0.5rem;"),
        CSSRule(selector: "[data-component=\"tooltip\"] [data-part=\"content\"][data-position=\"bottom\"]", declarations: "top: 100%; left: 50%; transform: translateX(-50%); margin-top: 0.5rem;"),
        CSSRule(selector: "[data-component=\"tooltip\"] [data-part=\"content\"][data-position=\"left\"]", declarations: "right: 100%; top: 50%; transform: translateY(-50%); margin-right: 0.5rem;"),
        CSSRule(selector: "[data-component=\"tooltip\"] [data-part=\"content\"][data-position=\"right\"]", declarations: "left: 100%; top: 50%; transform: translateY(-50%); margin-left: 0.5rem;"),
        CSSRule(selector: "[data-component=\"tooltip\"]:hover [data-part=\"content\"], [data-component=\"tooltip\"]:focus-within [data-part=\"content\"]", declarations: "display: block;"),
    ]

    private static let toggleCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"toggle\"]", declarations: "display: inline-flex; align-items: center; justify-content: center; font-weight: 500; border: 1px solid var(--color-border); border-radius: var(--button-radius); padding: var(--button-padding-y) var(--button-padding-x); cursor: pointer; background: transparent; color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"toggle\"][data-state=\"on\"]", declarations: "background: var(--color-accent); color: var(--color-surface); border-color: var(--color-accent);"),
        CSSRule(selector: "[data-component=\"toggle\"]:disabled", declarations: "opacity: 0.5; cursor: not-allowed;"),
    ]

    private static let breadcrumbCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"breadcrumb\"] ol", declarations: "display: flex; flex-wrap: wrap; align-items: center; gap: 0.25rem; list-style: none; padding: 0; margin: 0;"),
        CSSRule(selector: "[data-component=\"breadcrumb\"] [data-part=\"item\"]", declarations: "display: flex; align-items: center; gap: 0.25rem;"),
        CSSRule(selector: "[data-component=\"breadcrumb\"] [data-part=\"item\"] a", declarations: "text-decoration: none; color: var(--color-muted);"),
        CSSRule(selector: "[data-component=\"breadcrumb\"] [data-part=\"item\"] a:hover", declarations: "color: var(--color-text);"),
        CSSRule(selector: "[data-component=\"breadcrumb\"] [data-part=\"item\"][data-state=\"current\"]", declarations: "color: var(--color-text); font-weight: 500;"),
        CSSRule(selector: "[data-component=\"breadcrumb\"] [data-part=\"separator\"]", declarations: "color: var(--breadcrumb-separator-color);"),
    ]

    private static let paginationCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"pagination\"] ul", declarations: "display: flex; align-items: center; gap: 0.25rem; list-style: none; padding: 0; margin: 0;"),
        CSSRule(selector: "[data-component=\"pagination\"] [data-part=\"page\"] a, [data-component=\"pagination\"] [data-part=\"prev\"] a, [data-component=\"pagination\"] [data-part=\"next\"] a", declarations: "display: inline-flex; align-items: center; justify-content: center; min-width: 2rem; height: 2rem; padding: 0.25rem 0.5rem; border-radius: var(--pagination-radius); text-decoration: none; color: var(--color-text); border: 1px solid var(--color-border);"),
        CSSRule(selector: "[data-component=\"pagination\"] [data-part=\"page\"][data-state=\"active\"]", declarations: "background: var(--pagination-active-bg); color: var(--pagination-active-fg); border-radius: var(--pagination-radius); font-weight: 600; display: inline-flex; align-items: center; justify-content: center; min-width: 2rem; height: 2rem; padding: 0.25rem 0.5rem;"),
        CSSRule(selector: "[data-component=\"pagination\"] [data-state=\"disabled\"]", declarations: "color: var(--color-muted); cursor: not-allowed;"),
    ]

    private static let commandPaletteCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"command\"]", declarations: "background: var(--command-bg); color: var(--command-fg); border: 1px solid var(--command-border); border-radius: var(--command-radius); box-shadow: var(--command-shadow); max-width: 32rem; width: 100%; padding: 0; overflow: hidden;"),
        CSSRule(selector: "[data-component=\"command\"]::backdrop", declarations: "background: var(--dialog-overlay);"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"input\"]", declarations: "width: 100%; padding: 0.75rem 1rem; border: none; border-bottom: 1px solid var(--command-border); background: transparent; color: inherit; font: inherit; outline: none;"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"group\"]", declarations: "padding: 0.25rem;"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"heading\"]", declarations: "font-size: 0.75em; font-weight: 600; color: var(--color-muted); padding: 0.5rem 0.75rem 0.25rem;"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"list\"]", declarations: "list-style: none; padding: 0; margin: 0;"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"item\"] button", declarations: "display: flex; width: 100%; align-items: center; justify-content: space-between; padding: 0.5rem 0.75rem; border: none; background: transparent; cursor: pointer; border-radius: calc(var(--command-radius) * 0.5); color: inherit; font: inherit;"),
        CSSRule(selector: "[data-component=\"command\"] [data-part=\"shortcut\"]", declarations: "font-size: 0.75em; color: var(--color-muted);"),
    ]

    private static let editorCSSRules: [CSSRule] = [
        CSSRule(selector: "[data-component=\"editor\"]", declarations: "position: relative; border: 1px solid var(--editor-border); border-radius: var(--editor-radius); background: var(--editor-bg); color: var(--editor-fg); font-family: var(--editor-font-family); font-size: var(--editor-font-size); line-height: var(--editor-line-height); overflow: hidden; display: flex;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"gutter\"]", declarations: "background: var(--editor-gutter-bg); color: var(--editor-gutter-fg); width: var(--editor-gutter-width); text-align: right; padding: 0.5rem 0.5rem 0.5rem 0; user-select: none; flex-shrink: 0; font-size: 0.875em; opacity: 0.6; overflow: hidden;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"content\"]", declarations: "position: relative; flex: 1; overflow: auto;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"input\"]", declarations: "position: absolute; inset: 0; width: 100%; height: 100%; padding: 0.5rem; margin: 0; border: none; outline: none; background: transparent; color: transparent; caret-color: var(--editor-cursor-color); font: inherit; line-height: inherit; resize: none; white-space: pre; overflow: auto; z-index: 1;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"input\"]::selection", declarations: "background: var(--editor-selection-bg);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"highlight\"]", declarations: "padding: 0.5rem; margin: 0; pointer-events: none; white-space: pre; overflow: hidden; min-height: 100%;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"highlight\"] code", declarations: "font: inherit;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"autocomplete\"]", declarations: "display: none; position: absolute; z-index: 100; background: var(--editor-autocomplete-bg); border: 1px solid var(--editor-autocomplete-border); border-radius: var(--radius-base); box-shadow: var(--editor-autocomplete-shadow); max-height: 12rem; overflow-y: auto; min-width: 10rem; padding: 0.25rem;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"autocomplete\"][data-state=\"open\"]", declarations: "display: block;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"autocomplete\"] [data-part=\"option\"]", declarations: "padding: 0.375rem 0.5rem; cursor: pointer; border-radius: calc(var(--radius-base) * 0.5);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"autocomplete\"] [data-part=\"option\"][data-state=\"selected\"]", declarations: "background: var(--editor-autocomplete-selected); color: var(--color-surface);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"diagnostics\"]", declarations: "position: absolute; inset: 0; pointer-events: none; padding: 0.5rem; white-space: pre; overflow: hidden; z-index: 2;"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"hover\"]", declarations: "display: none; position: absolute; z-index: 100; background: var(--editor-hover-bg); border: 1px solid var(--editor-hover-border); border-radius: var(--radius-base); padding: 0.5rem 0.75rem; font-size: 0.875em; max-width: 24rem; box-shadow: var(--editor-autocomplete-shadow);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-part=\"hover\"][data-state=\"open\"]", declarations: "display: block;"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-keyword", declarations: "color: var(--editor-keyword); font-weight: 600;"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-string, [data-component=\"editor\"] .ts-template-string", declarations: "color: var(--editor-string);"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-comment", declarations: "color: var(--editor-comment); font-style: italic;"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-function, [data-component=\"editor\"] .ts-method", declarations: "color: var(--editor-function);"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-type, [data-component=\"editor\"] .ts-class", declarations: "color: var(--editor-type);"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-number, [data-component=\"editor\"] .ts-boolean", declarations: "color: var(--editor-number);"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-operator, [data-component=\"editor\"] .ts-punctuation", declarations: "color: var(--editor-operator);"),
        CSSRule(selector: "[data-component=\"editor\"] .ts-property, [data-component=\"editor\"] .ts-variable", declarations: "color: var(--editor-property);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-severity=\"error\"]", declarations: "text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-error);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-severity=\"warning\"]", declarations: "text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-warning);"),
        CSSRule(selector: "[data-component=\"editor\"] [data-severity=\"info\"]", declarations: "text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-info);"),
    ]

    private static let componentCSSGroups: [[CSSRule]] = [
        cardCSSRules, navBarCSSRules, buttonCSSRules, alertCSSRules, badgeCSSRules,
        dialogCSSRules, sheetCSSRules, accordionCSSRules, tabsCSSRules, toastCSSRules,
        dropdownCSSRules, inputCSSRules, textareaCSSRules, selectCSSRules, checkboxCSSRules,
        switchCSSRules, radioGroupCSSRules, sliderCSSRules, formLabelCSSRules,
        avatarCSSRules, progressCSSRules, skeletonCSSRules, separatorCSSRules,
        tooltipCSSRules, toggleCSSRules, breadcrumbCSSRules, paginationCSSRules,
        commandPaletteCSSRules, editorCSSRules,
    ]

    private static func appendComponentTokens(
        theme: some Theme,
        to output: inout String,
        indent: String = "  "
    ) {
        var tokens = defaultComponentTokens
        for (key, value) in theme.componentStyles {
            tokens[key] = value
        }
        guard !tokens.isEmpty else { return }
        output.append("\n\(indent)/* Component tokens */\n")
        for key in tokens.keys.sorted() {
            guard let value = tokens[key] else { continue }
            output.append("\(indent)--\(key): \(value);\n")
        }
    }

    private static func appendColorRoles(
        _ roles: [String: ColorToken],
        to output: inout String,
        indent: String = "  "
    ) {
        for key in roles.keys.sorted() {
            guard let token = roles[key] else { continue }
            output.append("\(indent)--color-\(key): \(token.resolvedCSSValue);\n")
        }
    }

    private static func appendFontFamilies(
        _ families: [String: String],
        to output: inout String,
        indent: String = "  "
    ) {
        for key in families.keys.sorted() {
            guard let value = families[key] else { continue }
            output.append("\(indent)--font-\(key): \(value);\n")
        }
    }
}

extension ColorToken {

    /// Resolves the token to a concrete CSS color value for theme emission.
    ///
    /// Unlike ``cssValue`` which emits `var()` references for semantic tokens,
    /// this property emits the literal value suitable for defining the custom
    /// property itself.
    var resolvedCSSValue: String {
        switch self {
        case .oklch(let l, let c, let h):
            return "oklch(\(l) \(c) \(h))"
        case .neutral(let s): return "var(--color-neutral-\(s))"
        case .blue(let s): return "var(--color-blue-\(s))"
        case .red(let s): return "var(--color-red-\(s))"
        case .green(let s): return "var(--color-green-\(s))"
        case .amber(let s): return "var(--color-amber-\(s))"
        case .sky(let s): return "var(--color-sky-\(s))"
        case .slate(let s): return "var(--color-slate-\(s))"
        case .cyan(let s): return "var(--color-cyan-\(s))"
        case .emerald(let s): return "var(--color-emerald-\(s))"
        case .custom(let name, let shade): return "var(--color-\(name)-\(shade))"
        case .surface: return "inherit"
        case .text: return "inherit"
        case .border: return "inherit"
        case .accent: return "inherit"
        case .muted: return "inherit"
        case .destructive: return "inherit"
        case .success: return "inherit"
        }
    }
}

extension Double {

    fileprivate var cssLength: String {
        "\(trimmed)px"
    }

    fileprivate var trimmed: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(self)
    }
}
