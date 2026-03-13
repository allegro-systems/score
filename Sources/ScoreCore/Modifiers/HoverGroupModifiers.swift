/// Modifiers for hover-based show/hide of child elements.
///
/// Use ``Node/hoverGroup()`` on a parent container and
/// ``Node/showOnGroupHover()`` on a direct child to reveal the child
/// only when the parent is hovered.
///
/// ```swift
/// Stack {
///     Text { "Menu" }
///     Stack { /* dropdown content */ }
///         .showOnGroupHover()
/// }
/// .hoverGroup()
/// ```
///
/// The CSS rules that power this behavior are emitted by
/// `ThemeCSSEmitter` as base styles, using `visibility` and `opacity`
/// to avoid specificity conflicts with component-scoped `display`
/// values.
extension Node {

    /// Marks this node as a hover group whose direct children can
    /// respond to its hover state via ``showOnGroupHover()``.
    public func hoverGroup() -> ModifiedNode<Self> {
        htmlAttribute("data-hover-group", "")
    }

    /// Hides this node by default and reveals it when its nearest
    /// ancestor hover group is hovered.
    ///
    /// The element remains in the DOM with its layout properties
    /// intact (e.g. `display: flex`) but is visually hidden via
    /// `visibility: hidden` and `opacity: 0` until the parent
    /// hover group receives a `:hover` event.
    public func showOnGroupHover() -> ModifiedNode<Self> {
        htmlAttribute("data-hover-target", "")
    }
}
