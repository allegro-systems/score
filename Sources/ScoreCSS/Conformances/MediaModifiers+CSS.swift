import ScoreCore

/// Enables CSS emission for `ObjectFitModifier` modifiers.
extension ObjectFitModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "object-fit", value: fit.rawValue)]
    }
}

/// Enables CSS emission for `ObjectPositionModifier` modifiers.
extension ObjectPositionModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "object-position", value: position.rawValue)]
    }
}
