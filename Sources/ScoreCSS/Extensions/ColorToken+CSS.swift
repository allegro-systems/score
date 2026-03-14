import ScoreCore

extension ColorToken {

    /// Renders this color token as a CSS value string.
    ///
    /// Semantic and named tokens emit CSS custom property references
    /// (e.g. `var(--color-surface)`). Palette tokens emit shade-specific
    /// references (e.g. `var(--color-blue-500)`). OKLCH tokens emit a
    /// literal `oklch()` function call.
    ///
    /// ### Example
    ///
    /// ```swift
    /// ColorToken.surface.cssValue       // "var(--color-surface)"
    /// ColorToken.blue(500).cssValue     // "var(--color-blue-500)"
    /// ColorToken.oklch(0.65, 0.18, 270).cssValue  // "oklch(0.65 0.18 270)"
    /// ```
    ///
    /// - Returns: A CSS-compatible color value string.
    public var cssValue: String {
        switch kind {
        case .semantic(let name): return "var(--color-\(name))"
        case .palette(let name, let shade): return "var(--color-\(name)-\(shade))"
        case .oklch(let l, let c, let h): return "oklch(\(l) \(c) \(h))"
        case .named(let name): return "var(--color-\(name))"
        }
    }
}
