import ScoreCore

/// Enables CSS emission for `ScrollBehaviorModifier` modifiers.
extension ScrollBehaviorModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "scroll-behavior", value: behavior.rawValue)]
    }
}

/// Enables CSS emission for `ScrollMarginModifier` modifiers.
extension ScrollMarginModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "scroll-margin", value: CSSEmitter.pixels(value))]
    }
}

/// Enables CSS emission for `ScrollPaddingModifier` modifiers.
extension ScrollPaddingModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "scroll-padding", value: CSSEmitter.pixels(value))]
    }
}

/// Enables CSS emission for `ScrollSnapModifier` modifiers.
extension ScrollSnapModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = [.init(property: "scroll-snap-type", value: type.rawValue)]
        if let v = align { result.append(.init(property: "scroll-snap-align", value: v.rawValue)) }
        return result
    }
}
