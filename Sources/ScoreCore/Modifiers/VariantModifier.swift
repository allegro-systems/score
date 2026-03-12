/// A named style variant that conditionally applies CSS overrides via a
/// data-attribute selector.
///
/// `VariantModifier` stores a variant name and a set of modifier overrides.
/// The CSS collector emits the overrides inside a `[data-variant~="<name>"]`
/// selector, so they only take effect when a parent element (or the element
/// itself) carries the matching `data-variant` attribute value.
///
/// ### Usage
///
/// Apply a variant using the `variant(_:_:)` modifier on any node:
///
/// ```swift
/// Article { ... }
///     .padding(16)
///     .variant("compact") { $0.padding(8) }
/// ```
///
/// Activate the variant by setting the data attribute on a parent:
///
/// ```swift
/// Div { content }
///     .dataAttribute("variant", "compact")
/// ```
///
/// ### CSS Mapping
///
/// Maps to a CSS `[data-variant~="<name>"]` selector wrapping the override
/// declarations, nested inside the component scope when applicable.
public struct VariantModifier: ModifierValue {

    /// The variant name used in the CSS `[data-variant~="<name>"]` selector.
    public let name: String

    /// The CSS modifier overrides to apply when this variant is active.
    public let overrides: [any ModifierValue]

    /// Creates a variant modifier.
    ///
    /// - Parameters:
    ///   - name: The variant name for the CSS selector.
    ///   - overrides: The modifier values to apply when the variant is active.
    public init(name: String, overrides: [any ModifierValue]) {
        self.name = name
        self.overrides = overrides
    }
}

/// A type whose cases can serve as variant names for conditional CSS styling.
///
/// Conform your enums to `CSSVariant` to use them directly with the
/// ``Node/variant(_:_:)-swift.method`` modifier:
///
/// ```swift
/// enum CardSize: String, CSSVariant {
///     case small, regular, large
/// }
///
/// Article { ... }
///     .variant(.small) { $0.padding(8) }
/// ```
///
/// ### CSS Mapping
///
/// The ``variantName`` is used as the value in the
/// `[data-variant~="<name>"]` CSS selector.
public protocol CSSVariant: Sendable {
    /// The string used as the variant identifier in CSS selectors.
    var variantName: String { get }
}

extension CSSVariant where Self: RawRepresentable, RawValue == String {
    public var variantName: String { rawValue }
}

extension Node {

    /// Applies style overrides that activate when a named variant is set.
    ///
    /// The transform closure receives the current node and returns a modified
    /// version. Only the **new** modifiers added by the transform are emitted
    /// inside the variant's CSS selector — base modifiers are not duplicated.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Div { content }
    ///     .size(width: 960)
    ///     .variant("wide") { $0.size(width: 1200) }
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to a CSS `[data-variant~="wide"]` selector wrapping the override
    /// declarations.
    ///
    /// - Parameters:
    ///   - name: The variant name for the CSS selector.
    ///   - transform: A closure that receives the node and returns its
    ///     modified form with variant-specific overrides.
    /// - Returns: A modified node carrying the variant overrides.
    public func variant(_ name: String, @NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        let transformed = transform(self)
        let overrides = VariantModifier.extractOverrides(
            from: transformed,
            originalModifierCount: VariantModifier.modifierCount(in: self)
        )
        return ModifiedNode(content: self, modifiers: [VariantModifier(name: name, overrides: overrides)])
    }

    /// Applies style overrides that activate when a typed variant is set.
    ///
    /// This overload accepts any ``CSSVariant`` value, using its
    /// ``CSSVariant/variantName`` as the CSS selector value.
    ///
    /// ### Example
    ///
    /// ```swift
    /// enum CardSize: String, CSSVariant {
    ///     case small, regular, large
    /// }
    ///
    /// Article { ... }
    ///     .variant(.small) { $0.padding(8) }
    /// ```
    ///
    /// - Parameters:
    ///   - variant: The variant value whose ``CSSVariant/variantName`` is used.
    ///   - transform: A closure that receives the node and returns its
    ///     modified form with variant-specific overrides.
    /// - Returns: A modified node carrying the variant overrides.
    public func variant<V: CSSVariant>(_ variant: V, @NodeBuilder _ transform: (Self) -> some Node) -> ModifiedNode<Self> {
        self.variant(variant.variantName, transform)
    }
}

extension VariantModifier {

    /// Extracts only the new modifiers added by a transform, discarding the
    /// original node's existing modifiers.
    ///
    /// The flattened modifier chain of the transformed node contains both the
    /// new modifiers (outermost) and the original modifiers (innermost). By
    /// knowing the original modifier count, we take only the prefix.
    static func extractOverrides(
        from transformed: any Node,
        originalModifierCount: Int
    ) -> [any ModifierValue] {
        let all = allModifiers(in: transformed)
        guard all.count > originalModifierCount else { return [] }
        return Array(all.prefix(all.count - originalModifierCount))
    }

    /// Counts the total number of modifier values in a node's modifier chain.
    static func modifierCount(in node: any Node) -> Int {
        guard let chain = node as? any ModifierChainLinkable else { return 0 }
        return chain.chainModifiers.count + modifierCount(in: chain.chainContent)
    }

    /// Collects all modifier values from a node's modifier chain in
    /// outermost-first order.
    private static func allModifiers(in node: any Node) -> [any ModifierValue] {
        guard let chain = node as? any ModifierChainLinkable else { return [] }
        return chain.chainModifiers + allModifiers(in: chain.chainContent)
    }
}
