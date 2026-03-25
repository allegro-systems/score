/// The line style used when rendering a border.
///
/// `BorderStyle` controls the visual pattern of a border stroke and maps
/// directly to the CSS `border-style` keyword values.
///
/// ### CSS Mapping
///
/// Maps to the CSS `border-style` property.
public enum BorderStyle: String, Sendable {
    /// A single, continuous solid line.
    ///
    /// CSS equivalent: `border-style: solid`.
    case solid

    /// A series of short rectangular dashes.
    ///
    /// CSS equivalent: `border-style: dashed`.
    case dashed

    /// A series of small dots.
    ///
    /// CSS equivalent: `border-style: dotted`.
    case dotted

    /// No border is rendered.
    ///
    /// CSS equivalent: `border-style: none`.
    case none
}

/// A modifier that applies a border to one or more edges of a node.
///
/// `BorderModifier` controls the width, color, style, optional corner radius, and
/// the specific edges on which the border is drawn. When `edges` is `nil`, the border
/// is applied to all four sides.
///
/// ### Example
///
/// ```swift
/// Card()
///     .border(width: 1, color: .border, style: .solid, radius: 8)
///
/// TextInput()
///     .border(width: 2, color: .accent, style: .solid, at: .bottom)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `border`, `border-radius`, and directional `border-{side}` properties.
public struct BorderModifier: ModifierValue {
    /// The thickness of the border stroke in points.
    public let width: Double

    /// The design-token color of the border.
    public let color: ColorToken

    /// The line style of the border (solid, dashed, dotted, or none).
    public let style: BorderStyle

    /// The corner radius applied to the node, in points.
    ///
    /// When `nil`, no border-radius is applied.
    public let radius: Double?

    /// The specific edges on which the border is drawn.
    ///
    /// When `nil`, the border is applied to all four edges.
    public let edges: Set<Edge>?

    /// Creates a border modifier.
    ///
    /// - Parameters:
    ///   - width: The border stroke width in points.
    ///   - color: The design-token color of the border.
    ///   - style: The line style (e.g., `.solid`, `.dashed`).
    ///   - radius: Optional corner radius in points.
    ///   - edges: The edges on which to apply the border. Pass `nil` for all edges.
    public init(
        width: Double,
        color: ColorToken,
        style: BorderStyle,
        radius: Double? = nil,
        edges: Set<Edge>? = nil
    ) {
        self.width = width
        self.color = color
        self.style = style
        self.radius = radius
        self.edges = edges
    }
}

/// A modifier that overrides only the border color of a node.
///
/// Use this when you need to change just the border color without
/// respecifying width and style — for example, inside a `.hover {}` block.
///
/// ### CSS Mapping
///
/// Maps to the CSS `border-color` property.
public struct BorderColorModifier: ModifierValue {
    /// The design-token color to apply to the border.
    public let color: ColorToken

    /// Creates a border color modifier.
    ///
    /// - Parameter color: The design-token color for the border.
    public init(_ color: ColorToken) {
        self.color = color
    }
}

extension Node {
    /// Overrides only the border color of this node.
    ///
    /// Use this modifier when the border width and style are already set
    /// and you only need to change the color — for example, inside a
    /// `.hover {}` block.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .border(width: 1, color: .border, style: .solid)
    ///     .hover { $0.borderColor(.accent) }
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `border-color` property.
    ///
    /// - Parameter color: The design-token color for the border.
    /// - Returns: A `ModifiedNode` with the border color modifier applied.
    public func borderColor(_ color: ColorToken) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [BorderColorModifier(color)])
    }
}

extension Node {
    /// Applies a border to this node using a variadic list of edges.
    ///
    /// When no edges are specified, the border is applied to all four sides.
    /// Combine with a corner `radius` to create rounded borders.
    ///
    /// ### Example
    ///
    /// ```swift
    /// TextInput()
    ///     .border(width: 1, color: .border, style: .solid, radius: 6)
    ///
    /// Divider()
    ///     .border(width: 1, color: .separator, style: .solid, at: .bottom)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `border`, `border-radius`, and directional `border-{side}`
    /// properties on the rendered element.
    ///
    /// - Parameters:
    ///   - width: The border stroke width in points.
    ///   - color: The design-token color of the border.
    ///   - style: The line style (e.g., `.solid`, `.dashed`).
    ///   - radius: Optional corner radius in points.
    ///   - edges: A variadic list of edges on which to draw the border. Omit for all edges.
    /// - Returns: A `ModifiedNode` with the border modifier applied.
    public func border(
        width: Double,
        color: ColorToken,
        style: BorderStyle,
        radius: Double? = nil,
        at edges: Edge...
    ) -> ModifiedNode<Self> {
        let configuredEdges = edges.isEmpty ? nil : Set(edges)
        let mod = BorderModifier(
            width: width, color: color, style: style, radius: radius, edges: configuredEdges)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Applies a border to this node using an array of edges.
    ///
    /// When the array is empty, the border is applied to all four sides.
    /// Combine with a corner `radius` to create rounded borders.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .border(width: 1, color: .border, style: .solid, radius: 8, at: [.top, .bottom])
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `border`, `border-radius`, and directional `border-{side}`
    /// properties on the rendered element.
    ///
    /// - Parameters:
    ///   - width: The border stroke width in points.
    ///   - color: The design-token color of the border.
    ///   - style: The line style (e.g., `.solid`, `.dashed`).
    ///   - radius: Optional corner radius in points.
    ///   - edges: An array of edges on which to draw the border. Pass an empty array for all edges.
    /// - Returns: A `ModifiedNode` with the border modifier applied.
    public func border(
        width: Double,
        color: ColorToken,
        style: BorderStyle,
        radius: Double? = nil,
        at edges: [Edge]
    ) -> ModifiedNode<Self> {
        let configuredEdges = edges.isEmpty ? nil : Set(edges)
        let mod = BorderModifier(
            width: width, color: color, style: style, radius: radius, edges: configuredEdges)
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
