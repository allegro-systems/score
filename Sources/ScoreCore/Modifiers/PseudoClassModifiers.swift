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

/// A declarative style override applied under a pseudo-class condition.
///
/// `PseudoStyle` represents a single CSS property change that takes effect
/// when its parent pseudo-class selector matches. Each case mirrors a
/// commonly overridden CSS property, keeping the API surface small and
/// discoverable while covering the most frequent interactive styling needs.
///
/// ### Example
///
/// ```swift
/// Button("Submit")
///     .background(.accent)
///     .hover(.background(.oklch(0.68, 0.10, 75)))
/// ```
///
/// ### CSS Mapping
///
/// Each case maps to a single CSS declaration emitted inside the
/// pseudo-class selector block.
public enum PseudoStyle: Sendable, Hashable {
    /// Overrides the background color.
    ///
    /// CSS equivalent: `background-color: <color>`.
    case background(ColorToken)

    /// Overrides the foreground (text) color.
    ///
    /// CSS equivalent: `color: <color>`.
    case foreground(ColorToken)

    /// Overrides the border color.
    ///
    /// CSS equivalent: `border-color: <color>`.
    case borderColor(ColorToken)

    /// Overrides the element opacity.
    ///
    /// CSS equivalent: `opacity: <value>`.
    case opacity(Double)

    /// Overrides the text decoration.
    ///
    /// CSS equivalent: `text-decoration: <value>`.
    case textDecoration(TextDecoration)

    /// Applies CSS transforms.
    ///
    /// CSS equivalent: `transform: <value>`.
    case transform([Transform])
}

/// A modifier that applies styles conditionally under a CSS pseudo-class.
///
/// `PseudoClassModifier` stores a pseudo-class selector and an array of
/// `PseudoStyle` overrides. The CSS pipeline emits these as a separate
/// rule set under the pseudo-class selector, sharing the same scope as
/// the element's base styles.
///
/// This modifier is transparent to the HTML renderer — it does not produce
/// a wrapper `<div>` or any base CSS declarations. The pseudo-class rule
/// is emitted alongside the base rule in the stylesheet.
///
/// ### Example
///
/// ```swift
/// Link(to: "/about") { "About" }
///     .font(size: 14, color: .muted)
///     .hover(.foreground(.text), .textDecoration(.none))
/// ```
///
/// ### CSS Output
///
/// ```css
/// .nav-link { font-size: 14px; color: var(--color-muted); }
/// .nav-link:hover { color: var(--color-text); text-decoration: none; }
/// ```
public struct PseudoClassModifier: ModifierValue {
    /// The pseudo-class under which the styles apply.
    public let pseudoClass: PseudoClass

    /// The style overrides to apply when the pseudo-class matches.
    public let styles: [PseudoStyle]

    /// Creates a pseudo-class modifier.
    ///
    /// - Parameters:
    ///   - pseudoClass: The pseudo-class condition (e.g. `.hover`).
    ///   - styles: The style overrides to apply.
    public init(_ pseudoClass: PseudoClass, styles: [PseudoStyle]) {
        self.pseudoClass = pseudoClass
        self.styles = styles
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
    ///     .hover(.background(.oklch(0.12, 0.01, 60)), .borderColor(.oklch(0.30, 0.03, 60)))
    /// ```
    ///
    /// - Parameter styles: The style overrides to apply on hover.
    /// - Returns: A `ModifiedNode` with the hover modifier applied.
    public func hover(_ styles: PseudoStyle...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [PseudoClassModifier(.hover, styles: styles)])
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
    ///     .focus(.borderColor(.accent))
    /// ```
    ///
    /// - Parameter styles: The style overrides to apply on focus.
    /// - Returns: A `ModifiedNode` with the focus modifier applied.
    public func focus(_ styles: PseudoStyle...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [PseudoClassModifier(.focus, styles: styles)])
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
    ///     .active(.background(.oklch(0.60, 0.10, 75)))
    /// ```
    ///
    /// - Parameter styles: The style overrides to apply while active.
    /// - Returns: A `ModifiedNode` with the active modifier applied.
    public func active(_ styles: PseudoStyle...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [PseudoClassModifier(.active, styles: styles)])
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
    ///     .focusVisible(.borderColor(.accent))
    /// ```
    ///
    /// - Parameter styles: The style overrides to apply on keyboard focus.
    /// - Returns: A `ModifiedNode` with the focus-visible modifier applied.
    public func focusVisible(_ styles: PseudoStyle...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [PseudoClassModifier(.focusVisible, styles: styles)])
    }
}
