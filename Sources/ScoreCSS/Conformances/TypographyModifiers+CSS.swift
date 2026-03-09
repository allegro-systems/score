import ScoreCore

extension FontModifier: CSSRepresentable {
    func cssDeclarations() -> [CSSDeclaration] {
        var result: [CSSDeclaration] = []

        // Font properties
        if let v = family { result.append(.init(property: "font-family", value: v.cssValue)) }
        if let v = size { result.append(.init(property: "font-size", value: CSSEmitter.pixels(v))) }
        if let v = weight { result.append(.init(property: "font-weight", value: v.cssValue)) }
        if let v = tracking { result.append(.init(property: "letter-spacing", value: CSSEmitter.pixels(v))) }
        if let v = lineHeight { result.append(.init(property: "line-height", value: CSSEmitter.number(v))) }
        if let v = color { result.append(.init(property: "color", value: v.cssValue)) }

        // Text style properties
        if let v = align { result.append(.init(property: "text-align", value: v.rawValue)) }
        if let v = transform { result.append(.init(property: "text-transform", value: v.rawValue)) }
        if let v = decoration { result.append(.init(property: "text-decoration", value: v.rawValue)) }
        if let v = wrap { result.append(.init(property: "text-wrap", value: v.rawValue)) }
        if let v = whiteSpace { result.append(.init(property: "white-space", value: v.rawValue)) }
        if let v = overflow { result.append(.init(property: "text-overflow", value: v.rawValue)) }
        if let v = overflowWrap { result.append(.init(property: "overflow-wrap", value: v.rawValue)) }
        if let v = wordBreak { result.append(.init(property: "word-break", value: v.rawValue)) }
        if let v = hyphens { result.append(.init(property: "hyphens", value: v.rawValue)) }
        if let v = lineClamp {
            result.append(.init(property: "display", value: "-webkit-box"))
            result.append(.init(property: "-webkit-box-orient", value: "vertical"))
            result.append(.init(property: "-webkit-line-clamp", value: String(v)))
            result.append(.init(property: "overflow", value: "hidden"))
        }
        if let v = indent { result.append(.init(property: "text-indent", value: CSSEmitter.pixels(v))) }

        return result
    }
}
