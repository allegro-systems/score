/// A modifier that merges default component styles with user-provided overrides.
///
/// `MergedStyleModifier` enables the shadcn-style pattern where components
/// define sensible default styles but user-supplied modifiers take precedence.
/// When CSS is emitted, declarations from `overrides` replace declarations
/// from `defaults` that share the same CSS property name.
///
/// ### Example
///
/// If the component default is `padding: 24px; border-radius: 8px` and the
/// user passes `padding: 32px`, the rendered CSS will be
/// `padding: 32px; border-radius: 8px` — the user's padding wins.
///
/// ### Usage in Components
///
/// ```swift
/// public var body: some Node {
///     Article { content }
///         .modifier(MergedStyleModifier(
///             defaults: [
///                 PaddingModifier(24),
///                 BorderModifier(width: 1, color: .border, style: .solid)
///             ],
///             overrides: userModifiers
///         ))
/// }
/// ```
public struct MergedStyleModifier: ModifierValue {

    /// The component's default modifier values.
    ///
    /// These provide baseline styling that renders when no user override
    /// targets the same CSS property.
    public let defaults: [any ModifierValue]

    /// User-provided modifier values that take precedence over defaults.
    ///
    /// When an override produces a CSS declaration with the same property
    /// name as a default, only the override's value is emitted.
    public let overrides: [any ModifierValue]

    /// Creates a merged style modifier.
    ///
    /// - Parameters:
    ///   - defaults: The component's default styles.
    ///   - overrides: User-provided styles that override defaults.
    public init(
        defaults: [any ModifierValue],
        overrides: [any ModifierValue] = []
    ) {
        self.defaults = defaults
        self.overrides = overrides
    }
}
