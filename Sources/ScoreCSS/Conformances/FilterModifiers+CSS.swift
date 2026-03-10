import ScoreCore

/// Enables CSS emission for `FilterModifier` modifiers.
extension FilterModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        let value = filters.map(\.cssValue).joined(separator: " ")
        return [.init(property: "filter", value: value)]
    }
}

/// Enables CSS emission for `BackdropFilterModifier` modifiers.
extension BackdropFilterModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        let value = filters.map(\.cssValue).joined(separator: " ")
        return [.init(property: "backdrop-filter", value: value)]
    }
}

/// Enables CSS emission for `BlendModeModifier` modifiers.
extension BlendModeModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "mix-blend-mode", value: mode.rawValue)]
    }
}
