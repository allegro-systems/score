import ScoreCore

/// Enables CSS emission for `HiddenModifier` modifiers.
extension HiddenModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "display", value: "none")]
    }
}

/// Enables CSS emission for `FlexModifier` modifiers.
extension FlexModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = [
            .init(property: "display", value: "flex"),
            .init(property: "flex-direction", value: direction.rawValue),
            .init(property: "flex-wrap", value: wraps ? "wrap" : "nowrap"),
        ]
        if let v = justify { result.append(.init(property: "justify-content", value: v.rawValue)) }
        if let v = align { result.append(.init(property: "align-items", value: v.rawValue)) }
        if let v = gap { result.append(.init(property: "gap", value: CSSEmitter.pixels(v))) }
        return result
    }
}

/// Enables CSS emission for `GridModifier` modifiers.
extension GridModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = [
            .init(property: "display", value: "grid"),
            .init(property: "grid-template-columns", value: "repeat(\(columns), 1fr)"),
        ]
        if let v = rows { result.append(.init(property: "grid-template-rows", value: "repeat(\(v), 1fr)")) }
        if let v = gap { result.append(.init(property: "gap", value: CSSEmitter.pixels(v))) }
        if let v = autoFlow { result.append(.init(property: "grid-auto-flow", value: v.rawValue)) }
        return result
    }
}
