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
    private static let defaultComponentTokens: [String: String] = [
        // Card
        "card-bg": "var(--color-surface)",
        "card-fg": "var(--color-text)",
        "card-border": "var(--color-border)",
        "card-radius": "var(--radius-base)",
        "card-padding": "calc(var(--spacing-unit) * 6)",
        "card-shadow": "0 1px 3px 0 oklch(0 0 0 / 0.1), 0 1px 2px -1px oklch(0 0 0 / 0.1)",

        // NavBar
        "navbar-bg": "var(--color-surface)",
        "navbar-fg": "var(--color-text)",
        "navbar-border": "var(--color-border)",
        "navbar-height": "calc(var(--spacing-unit) * 16)",
        "navbar-padding-x": "calc(var(--spacing-unit) * 6)",

        // Button
        "button-radius": "var(--radius-base)",
        "button-padding-x": "calc(var(--spacing-unit) * 4)",
        "button-padding-y": "calc(var(--spacing-unit) * 2)",
        "button-font-weight": "500",

        // Alert
        "alert-bg": "var(--color-surface)",
        "alert-fg": "var(--color-text)",
        "alert-border": "var(--color-border)",
        "alert-radius": "var(--radius-base)",
        "alert-padding": "calc(var(--spacing-unit) * 4)",

        // Badge
        "badge-radius": "999px",
        "badge-padding-x": "calc(var(--spacing-unit) * 2.5)",
        "badge-padding-y": "calc(var(--spacing-unit) * 0.5)",
        "badge-font-size": "calc(var(--type-scale-base) * 0.75)",
        "badge-font-weight": "500",

        // Dialog
        "dialog-bg": "var(--color-surface)",
        "dialog-fg": "var(--color-text)",
        "dialog-border": "var(--color-border)",
        "dialog-radius": "calc(var(--radius-base) * 1.5)",
        "dialog-padding": "calc(var(--spacing-unit) * 6)",
        "dialog-shadow": "0 25px 50px -12px oklch(0 0 0 / 0.25)",
        "dialog-overlay": "oklch(0 0 0 / 0.5)",

        // Sheet
        "sheet-bg": "var(--color-surface)",
        "sheet-fg": "var(--color-text)",
        "sheet-border": "var(--color-border)",

        // Accordion
        "accordion-border": "var(--color-border)",
        "accordion-padding": "calc(var(--spacing-unit) * 4)",

        // Tabs
        "tabs-border": "var(--color-border)",
        "tabs-active-fg": "var(--color-text)",
        "tabs-inactive-fg": "var(--color-muted)",

        // Toast
        "toast-bg": "var(--color-surface)",
        "toast-fg": "var(--color-text)",
        "toast-border": "var(--color-border)",
        "toast-radius": "var(--radius-base)",
        "toast-padding": "calc(var(--spacing-unit) * 4)",
        "toast-shadow": "0 4px 12px oklch(0 0 0 / 0.15)",

        // Dropdown
        "dropdown-bg": "var(--color-surface)",
        "dropdown-fg": "var(--color-text)",
        "dropdown-border": "var(--color-border)",
        "dropdown-radius": "var(--radius-base)",
        "dropdown-shadow": "0 4px 6px -1px oklch(0 0 0 / 0.1)",

        // Input
        "input-bg": "var(--color-surface)",
        "input-fg": "var(--color-text)",
        "input-border": "var(--color-border)",
        "input-radius": "var(--radius-base)",
        "input-padding-x": "calc(var(--spacing-unit) * 3)",
        "input-padding-y": "calc(var(--spacing-unit) * 2)",
        "input-focus-ring": "var(--color-accent)",

        // Avatar
        "avatar-radius": "999px",
        "avatar-bg": "var(--color-muted)",
        "avatar-size-sm": "calc(var(--spacing-unit) * 8)",
        "avatar-size-md": "calc(var(--spacing-unit) * 10)",
        "avatar-size-lg": "calc(var(--spacing-unit) * 12)",

        // Progress
        "progress-bg": "var(--color-border)",
        "progress-fill": "var(--color-accent)",
        "progress-radius": "999px",
        "progress-height": "calc(var(--spacing-unit) * 2)",

        // Skeleton
        "skeleton-bg": "var(--color-muted)",
        "skeleton-radius": "var(--radius-base)",

        // Separator
        "separator-color": "var(--color-border)",
        "separator-thickness": "1px",

        // Tooltip
        "tooltip-bg": "var(--color-text)",
        "tooltip-fg": "var(--color-surface)",
        "tooltip-radius": "calc(var(--radius-base) * 0.5)",
        "tooltip-padding": "calc(var(--spacing-unit) * 2)",

        // Breadcrumb
        "breadcrumb-separator-color": "var(--color-muted)",

        // Pagination
        "pagination-active-bg": "var(--color-accent)",
        "pagination-active-fg": "var(--color-surface)",
        "pagination-radius": "var(--radius-base)",

        // CommandPalette
        "command-bg": "var(--color-surface)",
        "command-fg": "var(--color-text)",
        "command-border": "var(--color-border)",
        "command-radius": "calc(var(--radius-base) * 1.5)",
        "command-shadow": "0 25px 50px -12px oklch(0 0 0 / 0.25)",

        // Switch / Toggle
        "switch-bg": "var(--color-border)",
        "switch-bg-checked": "var(--color-accent)",
        "switch-thumb": "var(--color-surface)",
        "switch-radius": "999px",

        // Editor
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

        // Syntax highlighting
        "editor-keyword": "oklch(0.55 0.15 300)",
        "editor-string": "oklch(0.55 0.12 150)",
        "editor-comment": "oklch(0.6 0.02 240)",
        "editor-function": "oklch(0.55 0.14 250)",
        "editor-type": "oklch(0.55 0.12 60)",
        "editor-number": "oklch(0.55 0.15 30)",
        "editor-operator": "var(--color-text)",
        "editor-property": "oklch(0.55 0.1 200)",

        // Editor LSP UI
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

    // MARK: - Component CSS Rules

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

        // ── Card ──
        css.append(
            """
            [data-component="card"] { background: var(--card-bg); color: var(--card-fg); border: 1px solid var(--card-border); border-radius: var(--card-radius); box-shadow: var(--card-shadow); overflow: hidden; }
            [data-component="card"] [data-part="header"] { padding: var(--card-padding); padding-bottom: 0; }
            [data-component="card"] [data-part="title"] { font-weight: 600; line-height: 1.4; }
            [data-component="card"] [data-part="description"] { color: var(--color-muted); font-size: 0.875em; }
            [data-component="card"] [data-part="content"] { padding: var(--card-padding); }
            [data-component="card"] [data-part="footer"] { padding: var(--card-padding); padding-top: 0; }

            """)

        // ── NavBar ──
        css.append(
            """
            [data-component="navbar"] { background: var(--navbar-bg); color: var(--navbar-fg); border-bottom: 1px solid var(--navbar-border); min-height: var(--navbar-height); padding-inline: var(--navbar-padding-x); }
            [data-component="navbar"] > nav { display: flex; align-items: center; height: 100%; gap: 1rem; }
            [data-component="navbar"] [data-part="brand"] { font-weight: 600; text-decoration: none; color: inherit; display: flex; align-items: center; gap: 0.5rem; }
            [data-component="navbar"] [data-part="content"] { display: flex; list-style: none; gap: 0.25rem; margin: 0; padding: 0; flex: 1; }
            [data-component="navbar"] [data-part="content"] a { text-decoration: none; color: inherit; padding: 0.5rem 0.75rem; border-radius: var(--button-radius); }
            [data-component="navbar"] [data-part="content"] [data-state="active"] a { font-weight: 600; }
            [data-component="navbar"] [data-part="actions"] { display: flex; align-items: center; gap: 0.5rem; }

            """)

        // ── Button ──
        css.append(
            """
            [data-component="button"] { display: inline-flex; align-items: center; justify-content: center; border-radius: var(--button-radius); padding: var(--button-padding-y) var(--button-padding-x); font-weight: var(--button-font-weight); cursor: pointer; border: 1px solid transparent; transition: background 0.15s, border-color 0.15s, color 0.15s; line-height: 1.25; }
            [data-component="button"][data-variant="default"] { background: var(--color-accent); color: var(--color-surface); }
            [data-component="button"][data-variant="outline"] { background: transparent; color: var(--color-text); border-color: var(--color-border); }
            [data-component="button"][data-variant="ghost"] { background: transparent; color: var(--color-text); }
            [data-component="button"][data-variant="destructive"] { background: var(--color-destructive); color: var(--color-surface); }
            [data-component="button"][data-size="small"] { font-size: 0.875em; padding: calc(var(--button-padding-y) * 0.75) calc(var(--button-padding-x) * 0.75); }
            [data-component="button"][data-size="large"] { font-size: 1.125em; padding: calc(var(--button-padding-y) * 1.25) calc(var(--button-padding-x) * 1.25); }
            [data-component="button"]:disabled { opacity: 0.5; cursor: not-allowed; }

            """)

        // ── Alert ──
        css.append(
            """
            [data-component="alert"] { background: var(--alert-bg); color: var(--alert-fg); border: 1px solid var(--alert-border); border-radius: var(--alert-radius); padding: var(--alert-padding); }
            [data-component="alert"] [data-part="title"] { font-weight: 600; }
            [data-component="alert"] [data-part="description"] { color: var(--color-muted); }
            [data-component="alert"][data-variant="destructive"] { border-left: 4px solid var(--color-destructive); }
            [data-component="alert"][data-variant="success"] { border-left: 4px solid var(--color-success); }
            [data-component="alert"][data-variant="warning"] { border-left: 4px solid oklch(0.75 0.15 80); }
            [data-component="alert"][data-variant="info"] { border-left: 4px solid var(--color-accent); }

            """)

        // ── Badge ──
        css.append(
            """
            [data-component="badge"] { display: inline-flex; align-items: center; border-radius: var(--badge-radius); padding: var(--badge-padding-y) var(--badge-padding-x); font-size: var(--badge-font-size); font-weight: var(--badge-font-weight); line-height: 1; border: 1px solid var(--color-border); }
            [data-component="badge"][data-variant="default"] { background: var(--color-surface); color: var(--color-text); }
            [data-component="badge"][data-variant="success"] { background: var(--color-success); color: var(--color-surface); border-color: transparent; }
            [data-component="badge"][data-variant="warning"] { background: oklch(0.75 0.15 80); color: oklch(0.3 0.05 80); border-color: transparent; }
            [data-component="badge"][data-variant="destructive"] { background: var(--color-destructive); color: var(--color-surface); border-color: transparent; }
            [data-component="badge"][data-variant="outline"] { background: transparent; color: var(--color-text); }

            """)

        // ── Dialog ──
        css.append(
            """
            [data-component="dialog"] { background: var(--dialog-bg); color: var(--dialog-fg); border: 1px solid var(--dialog-border); border-radius: var(--dialog-radius); box-shadow: var(--dialog-shadow); max-width: 32rem; width: 100%; padding: 0; }
            [data-component="dialog"]::backdrop { background: var(--dialog-overlay); }
            [data-component="dialog"] [data-part="header"] { padding: var(--dialog-padding); padding-bottom: 0; }
            [data-component="dialog"] [data-part="body"] { padding: var(--dialog-padding); }
            [data-component="dialog"] [data-part="footer"] { padding: var(--dialog-padding); padding-top: 0; display: flex; justify-content: flex-end; gap: 0.5rem; }

            """)

        // ── Sheet ──
        css.append(
            """
            [data-component="sheet"] { background: var(--sheet-bg); color: var(--sheet-fg); border: none; padding: 0; margin: 0; max-width: none; max-height: none; }
            [data-component="sheet"]::backdrop { background: var(--dialog-overlay); }
            [data-component="sheet"][data-side="right"] { position: fixed; inset: 0 0 0 auto; width: 24rem; border-left: 1px solid var(--sheet-border); }
            [data-component="sheet"][data-side="left"] { position: fixed; inset: 0 auto 0 0; width: 24rem; border-right: 1px solid var(--sheet-border); }
            [data-component="sheet"][data-side="top"] { position: fixed; inset: 0 0 auto 0; height: 16rem; border-bottom: 1px solid var(--sheet-border); }
            [data-component="sheet"][data-side="bottom"] { position: fixed; inset: auto 0 0 0; height: 16rem; border-top: 1px solid var(--sheet-border); }

            """)

        // ── Accordion ──
        css.append(
            """
            [data-component="accordion"] { border: 1px solid var(--accordion-border); border-radius: var(--radius-base); overflow: hidden; }
            [data-component="accordion"] [data-part="item"] { border-bottom: 1px solid var(--accordion-border); }
            [data-component="accordion"] [data-part="item"]:last-child { border-bottom: none; }
            [data-component="accordion"] [data-part="trigger"] { padding: var(--accordion-padding); cursor: pointer; font-weight: 500; list-style: none; width: 100%; display: flex; justify-content: space-between; align-items: center; }
            [data-component="accordion"] [data-part="trigger"]::-webkit-details-marker { display: none; }
            [data-component="accordion"] [data-part="content"] { padding: 0 var(--accordion-padding) var(--accordion-padding); }

            """)

        // ── Tabs ──
        css.append(
            """
            [data-component="tabs"] { }
            [data-component="tabs"] [data-part="trigger"] { padding: 0.5rem 1rem; cursor: pointer; border: none; background: transparent; font-weight: 500; color: var(--tabs-inactive-fg); border-bottom: 2px solid transparent; }
            [data-component="tabs"] [data-part="trigger"][data-state="active"] { color: var(--tabs-active-fg); border-bottom-color: var(--color-accent); }
            [data-component="tabs"] [data-part="panel"] { padding: 1rem 0; }
            [data-component="tabs"] [data-part="panel"][data-state="inactive"] { display: none; }

            """)

        // ── Toast ──
        css.append(
            """
            [data-component="toast"] { background: var(--toast-bg); color: var(--toast-fg); border: 1px solid var(--toast-border); border-radius: var(--toast-radius); padding: var(--toast-padding); box-shadow: var(--toast-shadow); }
            [data-component="toast"] [data-part="title"] { font-weight: 600; }
            [data-component="toast"] [data-part="description"] { color: var(--color-muted); font-size: 0.875em; }
            [data-component="toast"] [data-part="action"] { font-size: 0.75em; font-weight: 500; border: 1px solid var(--color-border); border-radius: calc(var(--radius-base) * 0.5); padding: 0.25rem 0.5rem; cursor: pointer; background: transparent; }
            [data-component="toast"][data-variant="success"] { border-left: 4px solid var(--color-success); }
            [data-component="toast"][data-variant="error"] { border-left: 4px solid var(--color-destructive); }
            [data-component="toast"][data-variant="warning"] { border-left: 4px solid oklch(0.75 0.15 80); }

            """)

        // ── Dropdown ──
        css.append(
            """
            [data-component="dropdown"] { position: relative; display: inline-block; }
            [data-component="dropdown"] [data-part="trigger"] { cursor: pointer; list-style: none; }
            [data-component="dropdown"] [data-part="trigger"]::-webkit-details-marker { display: none; }
            [data-component="dropdown"] [data-part="content"] { position: absolute; z-index: 50; min-width: 10rem; background: var(--dropdown-bg); color: var(--dropdown-fg); border: 1px solid var(--dropdown-border); border-radius: var(--dropdown-radius); box-shadow: var(--dropdown-shadow); padding: 0.25rem; list-style: none; margin: 0; }
            [data-component="dropdown"] [data-part="item"] { }
            [data-component="dropdown"] [data-part="item"] button, [data-component="dropdown"] [data-part="item"] a { display: block; width: 100%; padding: 0.5rem 0.75rem; border: none; background: transparent; text-align: start; cursor: pointer; border-radius: calc(var(--dropdown-radius) * 0.5); text-decoration: none; color: inherit; }

            """)

        // ── Input ──
        css.append(
            """
            [data-component="input"] { display: flex; flex-direction: column; gap: 0.375rem; }
            [data-component="input"] [data-part="label"] { font-weight: 500; color: var(--color-text); }
            [data-component="input"] [data-part="input"] { background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none; }
            [data-component="input"] [data-part="input"]:focus { border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent); }
            [data-component="input"][data-state="error"] [data-part="input"] { border-color: var(--color-destructive); }
            [data-component="input"] [data-part="error"] { color: var(--color-destructive); font-size: 0.875em; }
            [data-component="input"] [data-part="helper"] { color: var(--color-muted); font-size: 0.875em; }

            """)

        // ── Textarea ──
        css.append(
            """
            [data-component="textarea"] { display: flex; flex-direction: column; gap: 0.375rem; }
            [data-component="textarea"] [data-part="label"] { font-weight: 500; color: var(--color-text); }
            [data-component="textarea"] [data-part="textarea"] { background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none; resize: vertical; }
            [data-component="textarea"] [data-part="textarea"]:focus { border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent); }
            [data-component="textarea"][data-state="error"] [data-part="textarea"] { border-color: var(--color-destructive); }
            [data-component="textarea"] [data-part="error"] { color: var(--color-destructive); font-size: 0.875em; }
            [data-component="textarea"] [data-part="helper"] { color: var(--color-muted); font-size: 0.875em; }

            """)

        // ── Select ──
        css.append(
            """
            [data-component="select"] { display: flex; flex-direction: column; gap: 0.375rem; }
            [data-component="select"] [data-part="label"] { font-weight: 500; color: var(--color-text); }
            [data-component="select"] [data-part="select"] { background: var(--input-bg); color: var(--input-fg); border: 1px solid var(--input-border); border-radius: var(--input-radius); padding: var(--input-padding-y) var(--input-padding-x); font: inherit; outline: none; }
            [data-component="select"] [data-part="select"]:focus { border-color: var(--input-focus-ring); box-shadow: 0 0 0 2px color-mix(in oklch, var(--input-focus-ring) 25%, transparent); }

            """)

        // ── Checkbox ──
        css.append(
            """
            [data-component="checkbox"] { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; padding: 0.25rem; }
            [data-component="checkbox"] [data-part="control"] { accent-color: var(--color-accent); }

            """)

        // ── Switch ──
        css.append(
            """
            [data-component="switch"] { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; }
            [data-component="switch"] [data-part="control"] { appearance: none; width: 2.5rem; height: 1.5rem; background: var(--switch-bg); border-radius: var(--switch-radius); position: relative; cursor: pointer; transition: background 0.2s; border: none; }
            [data-component="switch"] [data-part="control"]:checked { background: var(--switch-bg-checked); }
            [data-component="switch"] [data-part="control"]::before { content: ""; position: absolute; width: 1.125rem; height: 1.125rem; border-radius: 50%; background: var(--switch-thumb); top: 0.1875rem; left: 0.1875rem; transition: transform 0.2s; }
            [data-component="switch"] [data-part="control"]:checked::before { transform: translateX(1rem); }

            """)

        // ── RadioGroup ──
        css.append(
            """
            [data-component="radio-group"] { border: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.5rem; }
            [data-component="radio-group"] [data-part="legend"] { font-weight: 500; color: var(--color-text); margin-bottom: 0.25rem; }
            [data-component="radio-group"] [data-part="option"] { display: flex; align-items: center; gap: 0.5rem; cursor: pointer; }
            [data-component="radio-group"] [data-part="control"] { accent-color: var(--color-accent); }

            """)

        // ── Slider ──
        css.append(
            """
            [data-component="slider"] { display: flex; flex-direction: column; gap: 0.375rem; }
            [data-component="slider"] [data-part="label"] { font-weight: 500; color: var(--color-text); }
            [data-component="slider"] [data-part="track"] { accent-color: var(--color-accent); width: 100%; }

            """)

        // ── FormLabel ──
        css.append(
            """
            [data-component="label"] { font-weight: 500; }

            """)

        // ── Avatar ──
        css.append(
            """
            [data-component="avatar"] { display: inline-flex; align-items: center; justify-content: center; overflow: hidden; border-radius: var(--avatar-radius); background: var(--avatar-bg); }
            [data-component="avatar"][data-size="small"] { width: var(--avatar-size-sm); height: var(--avatar-size-sm); }
            [data-component="avatar"][data-size="medium"] { width: var(--avatar-size-md); height: var(--avatar-size-md); }
            [data-component="avatar"][data-size="large"] { width: var(--avatar-size-lg); height: var(--avatar-size-lg); }
            [data-component="avatar"] [data-part="image"] { width: 100%; height: 100%; object-fit: cover; }
            [data-component="avatar"] [data-part="fallback"] { font-weight: 600; font-size: 0.875em; }

            """)

        // ── Progress ──
        css.append(
            """
            [data-component="progress"] { display: flex; flex-direction: column; gap: 0.375rem; }
            [data-component="progress"] [data-part="label"] { font-weight: 500; font-size: 0.875em; }
            [data-component="progress"] [data-part="track"] { background: var(--progress-bg); border-radius: var(--progress-radius); height: var(--progress-height); overflow: hidden; }
            [data-component="progress"] [data-part="fill"] { height: 100%; }
            [data-component="progress"] progress { appearance: none; width: 100%; height: 100%; border: none; }
            [data-component="progress"] progress::-webkit-progress-bar { background: transparent; }
            [data-component="progress"] progress::-webkit-progress-value { background: var(--progress-fill); border-radius: var(--progress-radius); }
            [data-component="progress"] progress::-moz-progress-bar { background: var(--progress-fill); border-radius: var(--progress-radius); }

            """)

        // ── Skeleton ──
        css.append(
            """
            [data-component="skeleton"] { background: var(--skeleton-bg); border-radius: var(--skeleton-radius); animation: score-skeleton-pulse 2s ease-in-out infinite; }
            @keyframes score-skeleton-pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }

            """)

        // ── Separator ──
        css.append(
            """
            [data-component="separator"] { border: none; border-top: var(--separator-thickness) solid var(--separator-color); margin: 0; }
            [data-component="separator"][data-orientation="vertical"] { border-top: none; border-left: var(--separator-thickness) solid var(--separator-color); height: 100%; width: 0; }

            """)

        // ── Tooltip ──
        css.append(
            """
            [data-component="tooltip"] { position: relative; display: inline-block; }
            [data-component="tooltip"] [data-part="content"] { display: none; position: absolute; z-index: 50; background: var(--tooltip-bg); color: var(--tooltip-fg); border-radius: var(--tooltip-radius); padding: var(--tooltip-padding); font-size: 0.875em; white-space: nowrap; pointer-events: none; }
            [data-component="tooltip"] [data-part="content"][data-position="top"] { bottom: 100%; left: 50%; transform: translateX(-50%); margin-bottom: 0.5rem; }
            [data-component="tooltip"] [data-part="content"][data-position="bottom"] { top: 100%; left: 50%; transform: translateX(-50%); margin-top: 0.5rem; }
            [data-component="tooltip"] [data-part="content"][data-position="left"] { right: 100%; top: 50%; transform: translateY(-50%); margin-right: 0.5rem; }
            [data-component="tooltip"] [data-part="content"][data-position="right"] { left: 100%; top: 50%; transform: translateY(-50%); margin-left: 0.5rem; }
            [data-component="tooltip"]:hover [data-part="content"], [data-component="tooltip"]:focus-within [data-part="content"] { display: block; }

            """)

        // ── Toggle ──
        css.append(
            """
            [data-component="toggle"] { display: inline-flex; align-items: center; justify-content: center; font-weight: 500; border: 1px solid var(--color-border); border-radius: var(--button-radius); padding: var(--button-padding-y) var(--button-padding-x); cursor: pointer; background: transparent; color: var(--color-text); }
            [data-component="toggle"][data-state="on"] { background: var(--color-accent); color: var(--color-surface); border-color: var(--color-accent); }
            [data-component="toggle"]:disabled { opacity: 0.5; cursor: not-allowed; }

            """)

        // ── Breadcrumb ──
        css.append(
            """
            [data-component="breadcrumb"] ol { display: flex; flex-wrap: wrap; align-items: center; gap: 0.25rem; list-style: none; padding: 0; margin: 0; }
            [data-component="breadcrumb"] [data-part="item"] { display: flex; align-items: center; gap: 0.25rem; }
            [data-component="breadcrumb"] [data-part="item"] a { text-decoration: none; color: var(--color-muted); }
            [data-component="breadcrumb"] [data-part="item"] a:hover { color: var(--color-text); }
            [data-component="breadcrumb"] [data-part="item"][data-state="current"] { color: var(--color-text); font-weight: 500; }
            [data-component="breadcrumb"] [data-part="separator"] { color: var(--breadcrumb-separator-color); }

            """)

        // ── Pagination ──
        css.append(
            """
            [data-component="pagination"] ul { display: flex; align-items: center; gap: 0.25rem; list-style: none; padding: 0; margin: 0; }
            [data-component="pagination"] [data-part="page"] a, [data-component="pagination"] [data-part="prev"] a, [data-component="pagination"] [data-part="next"] a { display: inline-flex; align-items: center; justify-content: center; min-width: 2rem; height: 2rem; padding: 0.25rem 0.5rem; border-radius: var(--pagination-radius); text-decoration: none; color: var(--color-text); border: 1px solid var(--color-border); }
            [data-component="pagination"] [data-part="page"][data-state="active"] { background: var(--pagination-active-bg); color: var(--pagination-active-fg); border-radius: var(--pagination-radius); font-weight: 600; display: inline-flex; align-items: center; justify-content: center; min-width: 2rem; height: 2rem; padding: 0.25rem 0.5rem; }
            [data-component="pagination"] [data-state="disabled"] { color: var(--color-muted); cursor: not-allowed; }

            """)

        // ── CommandPalette ──
        css.append(
            """
            [data-component="command"] { background: var(--command-bg); color: var(--command-fg); border: 1px solid var(--command-border); border-radius: var(--command-radius); box-shadow: var(--command-shadow); max-width: 32rem; width: 100%; padding: 0; overflow: hidden; }
            [data-component="command"]::backdrop { background: var(--dialog-overlay); }
            [data-component="command"] [data-part="input"] { width: 100%; padding: 0.75rem 1rem; border: none; border-bottom: 1px solid var(--command-border); background: transparent; color: inherit; font: inherit; outline: none; }
            [data-component="command"] [data-part="group"] { padding: 0.25rem; }
            [data-component="command"] [data-part="heading"] { font-size: 0.75em; font-weight: 600; color: var(--color-muted); padding: 0.5rem 0.75rem 0.25rem; }
            [data-component="command"] [data-part="list"] { list-style: none; padding: 0; margin: 0; }
            [data-component="command"] [data-part="item"] button { display: flex; width: 100%; align-items: center; justify-content: space-between; padding: 0.5rem 0.75rem; border: none; background: transparent; cursor: pointer; border-radius: calc(var(--command-radius) * 0.5); color: inherit; font: inherit; }
            [data-component="command"] [data-part="shortcut"] { font-size: 0.75em; color: var(--color-muted); }

            """)

        // ── Editor ──
        css.append(
            """
            [data-component="editor"] { position: relative; border: 1px solid var(--editor-border); border-radius: var(--editor-radius); background: var(--editor-bg); color: var(--editor-fg); font-family: var(--editor-font-family); font-size: var(--editor-font-size); line-height: var(--editor-line-height); overflow: hidden; display: flex; }
            [data-component="editor"] [data-part="gutter"] { background: var(--editor-gutter-bg); color: var(--editor-gutter-fg); width: var(--editor-gutter-width); text-align: right; padding: 0.5rem 0.5rem 0.5rem 0; user-select: none; flex-shrink: 0; font-size: 0.875em; opacity: 0.6; overflow: hidden; }
            [data-component="editor"] [data-part="content"] { position: relative; flex: 1; overflow: auto; }
            [data-component="editor"] [data-part="input"] { position: absolute; inset: 0; width: 100%; height: 100%; padding: 0.5rem; margin: 0; border: none; outline: none; background: transparent; color: transparent; caret-color: var(--editor-cursor-color); font: inherit; line-height: inherit; resize: none; white-space: pre; overflow: auto; z-index: 1; }
            [data-component="editor"] [data-part="input"]::selection { background: var(--editor-selection-bg); }
            [data-component="editor"] [data-part="highlight"] { padding: 0.5rem; margin: 0; pointer-events: none; white-space: pre; overflow: hidden; min-height: 100%; }
            [data-component="editor"] [data-part="highlight"] code { font: inherit; }
            [data-component="editor"] [data-part="autocomplete"] { display: none; position: absolute; z-index: 100; background: var(--editor-autocomplete-bg); border: 1px solid var(--editor-autocomplete-border); border-radius: var(--radius-base); box-shadow: var(--editor-autocomplete-shadow); max-height: 12rem; overflow-y: auto; min-width: 10rem; padding: 0.25rem; }
            [data-component="editor"] [data-part="autocomplete"][data-state="open"] { display: block; }
            [data-component="editor"] [data-part="autocomplete"] [data-part="option"] { padding: 0.375rem 0.5rem; cursor: pointer; border-radius: calc(var(--radius-base) * 0.5); }
            [data-component="editor"] [data-part="autocomplete"] [data-part="option"][data-state="selected"] { background: var(--editor-autocomplete-selected); color: var(--color-surface); }
            [data-component="editor"] [data-part="diagnostics"] { position: absolute; inset: 0; pointer-events: none; padding: 0.5rem; white-space: pre; overflow: hidden; z-index: 2; }
            [data-component="editor"] [data-part="hover"] { display: none; position: absolute; z-index: 100; background: var(--editor-hover-bg); border: 1px solid var(--editor-hover-border); border-radius: var(--radius-base); padding: 0.5rem 0.75rem; font-size: 0.875em; max-width: 24rem; box-shadow: var(--editor-autocomplete-shadow); }
            [data-component="editor"] [data-part="hover"][data-state="open"] { display: block; }
            [data-component="editor"] .ts-keyword { color: var(--editor-keyword); font-weight: 600; }
            [data-component="editor"] .ts-string, [data-component="editor"] .ts-template-string { color: var(--editor-string); }
            [data-component="editor"] .ts-comment { color: var(--editor-comment); font-style: italic; }
            [data-component="editor"] .ts-function, [data-component="editor"] .ts-method { color: var(--editor-function); }
            [data-component="editor"] .ts-type, [data-component="editor"] .ts-class { color: var(--editor-type); }
            [data-component="editor"] .ts-number, [data-component="editor"] .ts-boolean { color: var(--editor-number); }
            [data-component="editor"] .ts-operator, [data-component="editor"] .ts-punctuation { color: var(--editor-operator); }
            [data-component="editor"] .ts-property, [data-component="editor"] .ts-variable { color: var(--editor-property); }
            [data-component="editor"] [data-severity="error"] { text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-error); }
            [data-component="editor"] [data-severity="warning"] { text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-warning); }
            [data-component="editor"] [data-severity="info"] { text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: var(--editor-info); }

            """)

        return css
    }

    private static func appendComponentTokens(
        theme: some Theme,
        to output: inout String,
        indent: String = "  "
    ) {
        // Start with built-in defaults, then overlay user overrides.
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
        case .surface: return "var(--color-surface)"
        case .text: return "var(--color-text)"
        case .border: return "var(--color-border)"
        case .accent: return "var(--color-accent)"
        case .muted: return "var(--color-muted)"
        case .destructive: return "var(--color-destructive)"
        case .success: return "var(--color-success)"
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
