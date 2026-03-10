import ScoreCore

/// Enables CSS emission for `ListStyleModifier` modifiers.
extension ListStyleModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        if let v = type { result.append(.init(property: "list-style-type", value: v.rawValue)) }
        if let v = position { result.append(.init(property: "list-style-position", value: v.rawValue)) }
        return result
    }
}

/// Enables CSS emission for `TableStyleModifier` modifiers.
extension TableStyleModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        if let v = layout { result.append(.init(property: "table-layout", value: v.rawValue)) }
        if let v = borderCollapse { result.append(.init(property: "border-collapse", value: v.rawValue)) }
        if let v = borderSpacing { result.append(.init(property: "border-spacing", value: CSSEmitter.pixels(v))) }
        if let v = captionSide { result.append(.init(property: "caption-side", value: v.rawValue)) }
        return result
    }
}
