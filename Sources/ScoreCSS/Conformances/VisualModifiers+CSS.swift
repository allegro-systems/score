import ScoreCore

/// Enables CSS emission for `OpacityModifier` modifiers.
extension OpacityModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "opacity", value: CSSEmitter.number(value))]
    }
}

/// Enables CSS emission for `ShadowModifier` modifiers.
extension ShadowModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        let v = "\(CSSEmitter.pixels(x)) \(CSSEmitter.pixels(y)) \(CSSEmitter.pixels(blur)) \(CSSEmitter.pixels(spread)) \(color.cssValue)"
        return [.init(property: "box-shadow", value: v)]
    }
}

/// Enables CSS emission for `RadiusModifier` modifiers.
extension RadiusModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "border-radius", value: CSSEmitter.pixels(value))]
    }
}
