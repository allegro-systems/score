import ScoreCore

/// Enables CSS emission for `BorderModifier` modifiers.
extension BorderModifier: CSSRepresentable {
    /// Converts this modifier into one or more CSS declarations.
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []
        let shorthand = "\(CSSEmitter.pixels(width)) \(style.rawValue) \(color.cssValue)"
        if let edges, !edges.isEmpty {
            for edge in edges {
                result.append(.init(property: "border-\(edge.cssSuffix)", value: shorthand))
            }
        } else {
            result.append(.init(property: "border", value: shorthand))
        }
        if let r = radius {
            result.append(.init(property: "border-radius", value: CSSEmitter.pixels(r)))
        }
        return result
    }
}
