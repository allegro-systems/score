/// A modifier that attaches arbitrary HTML attributes to a node.
///
/// `HTMLAttributeModifier` allows components to emit `class`, `data-*`,
/// `role`, `aria-*`, and other HTML attributes on their rendered elements.
/// The HTML renderer extracts these attributes and merges them onto the
/// wrapping element.
///
/// This modifier does **not** produce CSS declarations. It is consumed
/// exclusively by the HTML renderer.
///
/// ### Example
///
/// ```swift
/// Stack { content }
///     .htmlAttribute("data-variant", "destructive")
///     .htmlAttribute("role", "alert")
/// ```
public struct HTMLAttributeModifier: ModifierValue {

    /// The HTML attributes to attach, as name-value pairs.
    public let attributes: [(name: String, value: String)]

    /// Creates an HTML attribute modifier.
    ///
    /// - Parameter attributes: The HTML attributes to attach as name-value pairs.
    public init(attributes: [(name: String, value: String)]) {
        self.attributes = attributes
    }
}

extension Node {

    /// Attaches an HTML attribute to this node.
    ///
    /// The attribute is emitted on the rendered element by the HTML renderer.
    /// This is useful for `data-*` attributes, ARIA properties, and other
    /// HTML-specific metadata.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Stack { content }
    ///     .htmlAttribute("data-state", "open")
    /// ```
    ///
    /// - Parameters:
    ///   - name: The attribute name (e.g. `"data-variant"`, `"role"`).
    ///   - value: The attribute value.
    /// - Returns: A `ModifiedNode` with the HTML attribute modifier applied.
    public func htmlAttribute(_ name: String, _ value: String) -> ModifiedNode<Self> {
        modifier(HTMLAttributeModifier(attributes: [(name: name, value: value)]))
    }

    /// Attaches multiple HTML attributes to this node.
    ///
    /// - Parameter attributes: An array of name-value pairs to attach.
    /// - Returns: A `ModifiedNode` with the HTML attribute modifier applied.
    public func htmlAttributes(_ attributes: [(String, String)]) -> ModifiedNode<Self> {
        modifier(HTMLAttributeModifier(attributes: attributes.map { (name: $0.0, value: $0.1) }))
    }

    /// Attaches a `data-*` attribute to this node.
    ///
    /// Convenience for `.htmlAttribute("data-\(name)", value)`.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Button { "Delete" }
    ///     .dataAttribute("variant", "destructive")
    /// // Renders: data-variant="destructive"
    /// ```
    ///
    /// - Parameters:
    ///   - name: The data attribute suffix (without the `data-` prefix).
    ///   - value: The attribute value.
    /// - Returns: A `ModifiedNode` with the HTML attribute modifier applied.
    public func dataAttribute(_ name: String, _ value: String) -> ModifiedNode<Self> {
        modifier(HTMLAttributeModifier(attributes: [(name: "data-\(name)", value: value)]))
    }

    /// Attaches one or more CSS class names to this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Stack { content }
    ///     .className("card", "card-elevated")
    /// ```
    ///
    /// - Parameter names: The CSS class names to attach.
    /// - Returns: A `ModifiedNode` with the HTML attribute modifier applied.
    public func className(_ names: String...) -> ModifiedNode<Self> {
        modifier(HTMLAttributeModifier(attributes: [(name: "class", value: names.joined(separator: " "))]))
    }
}
