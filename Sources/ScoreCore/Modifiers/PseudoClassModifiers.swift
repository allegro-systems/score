/// A CSS pseudo-class that conditionally applies styles based on user
/// interaction state.
///
/// `PseudoClass` maps directly to CSS pseudo-class selectors such as
/// `:hover`, `:focus`, and `:active`. Use it with `PseudoClassModifier`
/// to declare interaction-dependent styles in the modifier chain.
///
/// ### CSS Mapping
///
/// Each case maps to the corresponding CSS pseudo-class selector
/// (e.g. `.selector:hover`, `.selector:focus`).
public enum PseudoClass: String, Sendable, Hashable {
    /// Styles applied when the pointer is over the element.
    ///
    /// CSS equivalent: `:hover`.
    case hover

    /// Styles applied when the element has keyboard or programmatic focus.
    ///
    /// CSS equivalent: `:focus`.
    case focus

    /// Styles applied while the element is being activated (e.g. mouse button held down).
    ///
    /// CSS equivalent: `:active`.
    case active

    /// Styles applied when the element has focus that was triggered by keyboard
    /// navigation rather than pointer interaction.
    ///
    /// CSS equivalent: `:focus-visible`.
    case focusVisible = "focus-visible"
}

/// A modifier that applies styles conditionally under a CSS pseudo-class.
///
/// `PseudoClassModifier` stores a pseudo-class selector and an array of
/// modifier overrides. The CSS pipeline emits these as a separate
/// rule set under the pseudo-class selector, sharing the same scope as
/// the element's base styles.
///
/// The modifier overrides are extracted from a transform closure using
/// the same mechanism as breakpoint and variant modifiers, ensuring all
/// existing modifiers (`.font(color:)`, `.background()`, etc.) can be
/// reused inside pseudo-class blocks.
///
/// ### Example
///
/// ```swift
/// Link(to: "/about") { "About" }
///     .font(size: 14, color: .muted)
///     .hover { $0.font(color: .text) }
/// ```
///
/// ### CSS Output
///
/// ```css
/// .nav-link { font-size: 14px; color: var(--color-muted); }
/// .nav-link:hover { color: var(--color-text); }
/// ```
public struct PseudoClassModifier: ModifierValue, CustomModifierDescription {
    /// The pseudo-class under which the styles apply.
    public let pseudoClass: PseudoClass

    /// The modifier overrides to apply when the pseudo-class matches.
    public let overrides: [any ModifierValue]

    /// Creates a pseudo-class modifier.
    ///
    /// - Parameters:
    ///   - pseudoClass: The pseudo-class condition (e.g. `.hover`).
    ///   - overrides: The modifier overrides to apply.
    public init(_ pseudoClass: PseudoClass, overrides: [any ModifierValue]) {
        self.pseudoClass = pseudoClass
        self.overrides = overrides
    }

    public var devDescription: String {
        overridesDevDescription(label: pseudoClass.rawValue, overrides)
    }
}

extension Node {
    /// Applies style overrides when the element is hovered.
    ///
    /// Hover styles are emitted as a `:hover` pseudo-class selector in the
    /// generated CSS, targeting the same scope as the element's base styles.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Article { content }
    ///     .background(.surface)
    ///     .border(width: 1, color: .border)
    ///     .hover { $0.background(.elevated).borderColor(.accent) }
    /// ```
    ///
    /// - Parameter transform: A closure that receives the node and returns
    ///   its modified form with hover-specific overrides.
    /// - Returns: A `ModifiedNode` with the hover modifier applied.
    public func hover(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoClassModified(.hover, transform)
    }

    /// Applies style overrides when the element has focus.
    ///
    /// Focus styles are emitted as a `:focus` pseudo-class selector in the
    /// generated CSS.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Input()
    ///     .border(width: 1, color: .border)
    ///     .focus { $0.border(width: 1, color: .accent) }
    /// ```
    ///
    /// - Parameter transform: A closure that receives the node and returns
    ///   its modified form with focus-specific overrides.
    /// - Returns: A `ModifiedNode` with the focus modifier applied.
    public func focus(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoClassModified(.focus, transform)
    }

    /// Applies style overrides while the element is being activated.
    ///
    /// Active styles are emitted as an `:active` pseudo-class selector in the
    /// generated CSS.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Button("Press me")
    ///     .background(.accent)
    ///     .active { $0.background(.oklch(0.60, 0.10, 75)) }
    /// ```
    ///
    /// - Parameter transform: A closure that receives the node and returns
    ///   its modified form with active-specific overrides.
    /// - Returns: A `ModifiedNode` with the active modifier applied.
    public func active(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoClassModified(.active, transform)
    }

    /// Applies style overrides when the element has keyboard-triggered focus.
    ///
    /// Focus-visible styles are emitted as a `:focus-visible` pseudo-class
    /// selector in the generated CSS.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Button("Tab to me")
    ///     .focusVisible { $0.border(width: 2, color: .accent) }
    /// ```
    ///
    /// - Parameter transform: A closure that receives the node and returns
    ///   its modified form with focus-visible-specific overrides.
    /// - Returns: A `ModifiedNode` with the focus-visible modifier applied.
    public func focusVisible(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoClassModified(.focusVisible, transform)
    }

    private func pseudoClassModified(_ pseudoClass: PseudoClass, @NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        let transformed = transform(self)
        let overrides = VariantModifier.extractOverrides(
            from: transformed,
            originalModifierCount: VariantModifier.modifierCount(in: self)
        )
        return ModifiedNode(content: self, modifiers: [PseudoClassModifier(pseudoClass, overrides: overrides)])
    }
}
