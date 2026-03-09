import ScoreCore

/// Enables CSS emission for `FlexItemModifier` modifiers.
extension FlexItemModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        if let v = grow { result.append(.init(property: "flex-grow", value: CSSEmitter.number(v))) }
        if let v = shrink { result.append(.init(property: "flex-shrink", value: CSSEmitter.number(v))) }
        if let v = basis { result.append(.init(property: "flex-basis", value: CSSEmitter.pixels(v))) }
        if let v = alignSelf { result.append(.init(property: "align-self", value: v.rawValue)) }
        if let v = order { result.append(.init(property: "order", value: String(v))) }
        return result
    }
}

/// Enables CSS emission for `GridPlacementModifier` modifiers.
extension GridPlacementModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        if let v = column { result.append(.init(property: "grid-column", value: v)) }
        if let v = row { result.append(.init(property: "grid-row", value: v)) }
        if let v = area { result.append(.init(property: "grid-area", value: v)) }
        if let v = justifySelf { result.append(.init(property: "justify-self", value: v.rawValue)) }
        if let v = placeSelf { result.append(.init(property: "place-self", value: v)) }
        return result
    }
}
