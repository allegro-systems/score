import ScoreCore

/// Enables CSS emission for `SizeModifier` modifiers.
extension SizeModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        if let v = width { result.append(.init(property: "width", value: CSSEmitter.pixels(v))) }
        if let v = minWidth { result.append(.init(property: "min-width", value: CSSEmitter.pixels(v))) }
        if let v = maxWidth { result.append(.init(property: "max-width", value: CSSEmitter.pixels(v))) }
        if let v = height { result.append(.init(property: "height", value: CSSEmitter.pixels(v))) }
        if let v = minHeight { result.append(.init(property: "min-height", value: CSSEmitter.pixels(v))) }
        if let v = maxHeight { result.append(.init(property: "max-height", value: CSSEmitter.pixels(v))) }
        return result
    }
}

/// Enables CSS emission for `AspectRatioModifier` modifiers.
extension AspectRatioModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        [.init(property: "aspect-ratio", value: CSSEmitter.number(ratio))]
    }
}
