import ScoreCore

extension PseudoStyle {
    /// Converts this pseudo-style into a CSS declaration.
    ///
    /// Each `PseudoStyle` case maps to a single CSS property–value pair
    /// that is emitted inside the pseudo-class selector block by
    /// `CSSCollector`.
    func cssDeclaration() -> CSSDeclaration {
        switch self {
        case .background(let color):
            .init(property: "background-color", value: color.cssValue)
        case .foreground(let color):
            .init(property: "color", value: color.cssValue)
        case .borderColor(let color):
            .init(property: "border-color", value: color.cssValue)
        case .opacity(let value):
            .init(property: "opacity", value: CSSEmitter.number(value))
        case .textDecoration(let value):
            .init(property: "text-decoration", value: value.rawValue)
        case .transform(let transforms):
            .init(property: "transform", value: transforms.map(\.cssValue).joined(separator: " "))
        }
    }
}
