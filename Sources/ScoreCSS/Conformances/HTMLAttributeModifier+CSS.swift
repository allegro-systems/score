import ScoreCore

/// `HTMLAttributeModifier` does not produce CSS declarations.
///
/// HTML attributes (`data-*`, `class`, `role`, `aria-*`) are consumed by
/// the HTML renderer, not the CSS emitter.
extension HTMLAttributeModifier: CSSRepresentable {
    func cssDeclarations() -> [CSSDeclaration] { [] }
}
