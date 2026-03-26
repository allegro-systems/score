/// A CSS pseudo-element that targets a specific part of a node's rendering.
///
/// `PseudoElement` maps directly to CSS pseudo-element selectors such as
/// `::placeholder`, `::before`, and `::after`. Use it with
/// `PseudoElementModifier` to declare pseudo-element-dependent styles in
/// the modifier chain.
///
/// ### CSS Mapping
///
/// Each case maps to the corresponding CSS pseudo-element selector
/// (e.g. `.selector::placeholder`).
public enum PseudoElement: String, Sendable, Hashable {
    /// Styles applied to the placeholder text of an input or textarea.
    ///
    /// CSS equivalent: `::placeholder`.
    case placeholder

    /// Styles applied to a generated element before the node's content.
    ///
    /// CSS equivalent: `::before`.
    case before

    /// Styles applied to a generated element after the node's content.
    ///
    /// CSS equivalent: `::after`.
    case after

    /// Styles applied to the user's text selection within the node.
    ///
    /// CSS equivalent: `::selection`.
    case selection
}

/// A modifier that applies styles to a CSS pseudo-element of a node.
///
/// `PseudoElementModifier` stores a pseudo-element selector and an array of
/// modifier overrides. The CSS pipeline emits these as a separate
/// rule set under the pseudo-element selector, sharing the same scope as
/// the element's base styles.
///
/// ### Example
///
/// ```swift
/// Input(type: .text, name: "email", placeholder: "you@example.com")
///     .font(.sans, size: 14, color: .text)
///     .placeholder { $0.font(color: .muted) }
/// ```
///
/// ### CSS Output
///
/// ```css
/// .settings-input { font-size: 14px; color: var(--color-text); }
/// .settings-input::placeholder { color: var(--color-muted); }
/// ```
public struct PseudoElementModifier: ModifierValue, CustomModifierDescription {
    /// The pseudo-element under which the styles apply.
    public let pseudoElement: PseudoElement

    /// The modifier overrides to apply to the pseudo-element.
    public let overrides: [any ModifierValue]

    /// Creates a pseudo-element modifier.
    ///
    /// - Parameters:
    ///   - pseudoElement: The pseudo-element target (e.g. `.placeholder`).
    ///   - overrides: The modifier overrides to apply.
    public init(_ pseudoElement: PseudoElement, overrides: [any ModifierValue]) {
        self.pseudoElement = pseudoElement
        self.overrides = overrides
    }

    public var devDescription: String {
        overridesDevDescription(label: pseudoElement.rawValue, overrides)
    }
}

extension Node {
    /// Applies style overrides to the placeholder text of an input or textarea.
    ///
    /// ```swift
    /// Input(type: .email, name: "email", placeholder: "you@example.com")
    ///     .font(.sans, size: 14, color: .text)
    ///     .placeholder { $0.font(color: .muted) }
    /// ```
    ///
    /// - Parameter transform: A closure returning the placeholder-state overrides.
    /// - Returns: A `ModifiedNode` with the placeholder modifier applied.
    public func placeholder(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoElementModified(.placeholder, transform)
    }

    /// Applies style overrides to user-selected text within this node.
    ///
    /// ```swift
    /// Paragraph { "Select this text" }
    ///     .selection { $0.background(.accent).font(color: .bg) }
    /// ```
    ///
    /// - Parameter transform: A closure returning the selection-state overrides.
    /// - Returns: A `ModifiedNode` with the selection modifier applied.
    public func selection(@NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        pseudoElementModified(.selection, transform)
    }

    private func pseudoElementModified(_ pseudoElement: PseudoElement, @NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        let transformed = transform(self)
        let overrides = VariantModifier.extractOverrides(
            from: transformed,
            originalModifierCount: VariantModifier.modifierCount(in: self)
        )
        return ModifiedNode(content: self, modifiers: [PseudoElementModifier(pseudoElement, overrides: overrides)])
    }
}
