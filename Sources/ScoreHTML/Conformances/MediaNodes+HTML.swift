import ScoreCore

extension Image: HTMLVoidElement {
    package var htmlTagName: String { "img" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src), ("alt", alt)]
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        if let v = loading { a.append(("loading", v.rawValue)) }
        if let v = decoding { a.append(("decoding", v.rawValue)) }
        return a
    }
}

extension Figure: HTMLContainerElement {
    package var htmlTagName: String { "figure" }
}

extension FigureCaption: HTMLContainerElement {
    package var htmlTagName: String { "figcaption" }
}

extension Source: HTMLVoidElement {
    package var htmlTagName: String { "source" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src)]
        if let v = type { a.append(("type", v)) }
        if let v = media { a.append(("media", v)) }
        return a
    }
}

extension Track: HTMLVoidElement {
    package var htmlTagName: String { "track" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src)]
        if let v = kind { a.append(("kind", v.rawValue)) }
        if let v = label { a.append(("label", v)) }
        if let v = languageCode { a.append(("srclang", v)) }
        if isDefault { a.append(("default", "")) }
        return a
    }
}

extension Audio: HTMLContainerElement {
    package var htmlTagName: String { "audio" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = src { a.append(("src", v)) }
        if showsControls { a.append(("controls", "")) }
        if autoplays { a.append(("autoplay", "")) }
        if loops { a.append(("loop", "")) }
        if isMuted { a.append(("muted", "")) }
        if let v = preload { a.append(("preload", v.rawValue)) }
        return a
    }
}

extension Video: HTMLContainerElement {
    package var htmlTagName: String { "video" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = src { a.append(("src", v)) }
        if showsControls { a.append(("controls", "")) }
        if autoplays { a.append(("autoplay", "")) }
        if loops { a.append(("loop", "")) }
        if isMuted { a.append(("muted", "")) }
        if let v = preload { a.append(("preload", v.rawValue)) }
        if let v = poster { a.append(("poster", v)) }
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        return a
    }
}

extension Picture: HTMLContainerElement {
    package var htmlTagName: String { "picture" }
}

extension Canvas: HTMLContainerElement {
    package var htmlTagName: String { "canvas" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        return a
    }
}

// MARK: - SVG Elements

extension Svg: HTMLContainerElement {
    package var htmlTagName: String { "svg" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("xmlns", "http://www.w3.org/2000/svg")]
        if let v = viewBox { a.append(("viewBox", v)) }
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        if let v = fill { a.append(("fill", v)) }
        return a
    }
}

extension Path: HTMLVoidElement {
    package var htmlTagName: String { "path" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("d", d)]
        if let v = stroke { a.append(("stroke", v)) }
        if let v = strokeWidth { a.append(("stroke-width", svgNumber(v))) }
        if let v = strokeLinecap { a.append(("stroke-linecap", v)) }
        if let v = strokeLinejoin { a.append(("stroke-linejoin", v)) }
        if let v = fill { a.append(("fill", v)) }
        if let v = opacity { a.append(("opacity", svgNumber(v))) }
        return a
    }
}

extension Circle: HTMLVoidElement {
    package var htmlTagName: String { "circle" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [
            ("cx", svgNumber(cx)),
            ("cy", svgNumber(cy)),
            ("r", svgNumber(r)),
        ]
        if let v = fill { a.append(("fill", v)) }
        if let v = stroke { a.append(("stroke", v)) }
        if let v = strokeWidth { a.append(("stroke-width", svgNumber(v))) }
        if let v = opacity { a.append(("opacity", svgNumber(v))) }
        return a
    }
}

extension SvgRect: HTMLVoidElement {
    package var htmlTagName: String { "rect" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [
            ("x", svgNumber(x)),
            ("y", svgNumber(y)),
            ("width", svgNumber(width)),
            ("height", svgNumber(height)),
        ]
        if let v = rx { a.append(("rx", svgNumber(v))) }
        if let v = ry { a.append(("ry", svgNumber(v))) }
        if let v = fill { a.append(("fill", v)) }
        if let v = stroke { a.append(("stroke", v)) }
        if let v = strokeWidth { a.append(("stroke-width", svgNumber(v))) }
        if let v = opacity { a.append(("opacity", svgNumber(v))) }
        return a
    }
}

extension SvgLine: HTMLVoidElement {
    package var htmlTagName: String { "line" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [
            ("x1", svgNumber(x1)),
            ("y1", svgNumber(y1)),
            ("x2", svgNumber(x2)),
            ("y2", svgNumber(y2)),
        ]
        if let v = stroke { a.append(("stroke", v)) }
        if let v = strokeWidth { a.append(("stroke-width", svgNumber(v))) }
        if let v = strokeLinecap { a.append(("stroke-linecap", v)) }
        if let v = opacity { a.append(("opacity", svgNumber(v))) }
        return a
    }
}

/// Formats a `Double` for SVG attributes, omitting the decimal point for
/// whole numbers (e.g. `1.0` → `"1"`, `1.5` → `"1.5"`).
private func svgNumber(_ value: Double) -> String {
    value.cleanValue
}
