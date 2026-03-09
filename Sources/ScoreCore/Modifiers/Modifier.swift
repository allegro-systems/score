/// A type that can transform a node into a modified form.
///
/// `Modifier` represents a stateless, composable transformation that wraps
/// a node in additional behaviour or styling. Implementing `apply(to:)`
/// returns a new node — typically a `ModifiedNode` carrying both the
/// original content and the modifier's value — without mutating the
/// original node.
///
/// ### Implementing a Modifier
///
/// ```swift
/// struct PaddingModifier: Modifier {
///     let insets: EdgeInsets
///
///     func apply(to node: some Node) -> ModifiedNode<some Node> {
///         node.modifier(PaddingValue(insets: insets))
///     }
/// }
/// ```
///
/// ### Applying Modifiers
///
/// Modifiers are usually applied through the `Node.modifier(_:)` extension
/// rather than calling `apply(to:)` directly:
///
/// ```swift
/// TextNode("Hello")
///     .modifier(BackgroundColorValue(color: .surface))
/// ```
///
/// - Note: All conforming types must be `Sendable` so that modifier
///   instances can be safely shared across concurrency boundaries.
public protocol Modifier: Sendable {

    /// The concrete node type produced after applying this modifier.
    ///
    /// For most modifiers this will be `ModifiedNode<Content>` where
    /// `Content` is the input node type, but custom modifier implementations
    /// may return any `Node`-conforming type.
    associatedtype ModifiedBody: Node

    /// Applies this modifier to the given node and returns the result.
    ///
    /// Implementations should wrap `node` with any additional structure or
    /// metadata required by this modifier. The original `node` must not be
    /// mutated.
    ///
    /// - Parameter node: The node to modify.
    /// - Returns: A new node that incorporates the modifications described
    ///   by this modifier.
    func apply(to node: some Node) -> ModifiedBody
}

/// A node that pairs a content node with an ordered list of modifier values.
///
/// `ModifiedNode` is the result of calling `Node.modifier(_:)`. It stores
/// the original `content` node together with the `modifiers` that have been
/// applied to it. Renderers inspect `modifiers` to apply styling, layout
/// constraints, accessibility attributes, and other decorations to the
/// rendered output.
///
/// Multiple modifiers can be chained; each call to `.modifier(_:)` wraps
/// the current node in a new `ModifiedNode` carrying the additional modifier,
/// creating a nested structure where each level holds a single modifier.
/// Renderers walk the nesting levels to collect all modifiers in order.
///
/// ```swift
/// let node = Text { "Score" }
///     .modifier(FontValue(size: 24, weight: .bold))
///     .modifier(ForegroundColorValue(color: .accent))
/// // Creates: ModifiedNode(content: ModifiedNode(content: Text, modifiers: [FontValue]), modifiers: [ForegroundColorValue])
/// ```
///
/// - Note: `ModifiedNode` is a primitive node — its `body` property is
///   `Never` and must never be called directly.
public struct ModifiedNode<Content: Node>: Node {

    /// The original, unmodified node that this wrapper decorates.
    ///
    /// Renderers first render `content` and then apply each entry in
    /// `modifiers` to the resulting output.
    public let content: Content

    /// The ordered list of modifier values associated with this node.
    ///
    /// Modifiers are stored as existentials (`any ModifierValue`) so that
    /// heterogeneous modifier types can be accumulated in a single array.
    /// Renderers cast each entry to its concrete `ModifierValue` type to
    /// extract the associated styling or behaviour data.
    ///
    /// Modifiers are applied in the order they were added — earlier entries
    /// in the array correspond to modifiers applied closer to the original
    /// node.
    public let modifiers: [any ModifierValue]

    /// The body of `ModifiedNode`, which is never accessible at runtime.
    ///
    /// `ModifiedNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }

    /// Flattens a chain of nested `ModifiedNode` wrappers into a single
    /// combined modifier array and the innermost non-modified content node.
    ///
    /// When modifiers are chained (e.g. `.padding(8).background(.red)`),
    /// each call wraps in a new `ModifiedNode`. This method walks inward,
    /// collecting all modifiers in application order.
    ///
    /// - Returns: A tuple of all collected modifiers (outermost first) and
    ///   the innermost content node.
    public func flattenedChain() -> (modifiers: [any ModifierValue], innerContent: any Node) {
        var allModifiers = modifiers
        var current: any Node = content
        while let inner = current as? any ModifierChainLinkable {
            allModifiers.append(contentsOf: inner.chainModifiers)
            current = inner.chainContent
        }
        return (allModifiers, current)
    }
}

/// A node that can be walked as part of a modifier chain, enabling
/// `flattenedChain()` to traverse nested `ModifiedNode` wrappers
/// without knowing their generic parameter.
public protocol ModifierChainLinkable {
    /// The modifier values at this level of the chain.
    var chainModifiers: [any ModifierValue] { get }
    /// The content node wrapped by this level of the chain.
    var chainContent: any Node { get }
}

extension ModifiedNode: ModifierChainLinkable {
    public var chainModifiers: [any ModifierValue] { modifiers }
    public var chainContent: any Node { content }
}

/// A marker protocol for values that carry modifier data.
///
/// `ModifierValue` is a lightweight protocol that all concrete modifier
/// payloads conform to. It has no required members beyond `Sendable`; its
/// purpose is to provide a common existential type (`any ModifierValue`)
/// that `ModifiedNode` can store in a heterogeneous array.
///
/// Conforming types typically hold the configuration for a specific
/// modifier — for example, a color token, a font descriptor, or an
/// accessibility label — and are inspected by renderers to produce
/// platform-specific output.
///
/// ### Defining a Custom ModifierValue
///
/// ```swift
/// struct OpacityValue: ModifierValue {
///     let opacity: Double
/// }
///
/// extension Node {
///     func opacity(_ value: Double) -> ModifiedNode<Self> {
///         modifier(OpacityValue(opacity: value))
///     }
/// }
/// ```
///
/// - Note: All conforming types must be `Sendable` so that modifier values
///   can be safely shared across concurrency boundaries.
public protocol ModifierValue: Sendable {}

extension Node {

    /// Wraps this node in a `ModifiedNode` carrying the given modifier value.
    ///
    /// This is the primary way to attach styling, layout, or accessibility
    /// information to a node. Successive calls to `modifier(_:)` accumulate
    /// modifier values in the order they are applied.
    ///
    /// ### Example
    ///
    /// ```swift
    /// struct StyledLabel: Node {
    ///     var body: some Node {
    ///         TextNode("Score")
    ///             .modifier(FontValue(size: 18, weight: .semibold))
    ///             .modifier(ForegroundColorValue(color: .accent))
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter modifier: The modifier value to attach to this node.
    /// - Returns: A `ModifiedNode` that wraps `self` and records `modifier`
    ///   in its `modifiers` array.
    public func modifier<M: ModifierValue>(_ modifier: M) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [modifier])
    }
}
