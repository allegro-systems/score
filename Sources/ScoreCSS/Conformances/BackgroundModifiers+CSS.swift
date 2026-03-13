import ScoreCore

/// Enables CSS emission for `BackgroundModifier` modifiers.
extension BackgroundModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "background-color", value: color.cssValue)]
    }
}

/// Enables CSS emission for `BackgroundGradientModifier` modifiers.
extension BackgroundGradientModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        let g = gradient
        let opacityPercent = Int(g.opacity * 100)
        let colorValue = "color-mix(in oklch, \(g.color.cssValue) \(opacityPercent)%, transparent)"
        let value = "radial-gradient(ellipse \(Int(g.width))% \(Int(g.height))% at \(g.position.rawValue), \(colorValue), transparent)"
        return [.init(property: "background-image", value: value)]
    }
}

/// Enables CSS emission for `BackgroundImageModifier` modifiers.
extension BackgroundImageModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = [
            .init(property: "background-image", value: "url('\(url)')")
        ]
        if let v = size { result.append(.init(property: "background-size", value: v.rawValue)) }
        if let v = position { result.append(.init(property: "background-position", value: v.rawValue)) }
        if let v = repeatMode { result.append(.init(property: "background-repeat", value: v.rawValue)) }
        if let v = clip { result.append(.init(property: "background-clip", value: v.rawValue)) }
        return result
    }
}
