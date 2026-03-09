import ScoreCore

/// Enables CSS emission for `PositionModifier` modifiers.
extension PositionModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = [.init(property: "position", value: mode.rawValue)]
        if let v = top { result.append(.init(property: "top", value: CSSEmitter.pixels(v))) }
        if let v = bottom { result.append(.init(property: "bottom", value: CSSEmitter.pixels(v))) }
        if let v = leading { result.append(.init(property: "inset-inline-start", value: CSSEmitter.pixels(v))) }
        if let v = trailing { result.append(.init(property: "inset-inline-end", value: CSSEmitter.pixels(v))) }
        return result
    }
}

/// Enables CSS emission for `ZIndexModifier` modifiers.
extension ZIndexModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "z-index", value: String(value))]
    }
}
