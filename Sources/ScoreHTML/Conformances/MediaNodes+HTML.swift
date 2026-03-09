import ScoreCore

extension Image: HTMLVoidElement {
    var htmlTagName: String { "img" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src), ("alt", alt)]
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        if let v = loading { a.append(("loading", v.rawValue)) }
        if let v = decoding { a.append(("decoding", v.rawValue)) }
        return a
    }
}

extension Figure: HTMLContainerElement {
    var htmlTagName: String { "figure" }
}

extension FigureCaption: HTMLContainerElement {
    var htmlTagName: String { "figcaption" }
}

extension Source: HTMLVoidElement {
    var htmlTagName: String { "source" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src)]
        if let v = type { a.append(("type", v)) }
        if let v = media { a.append(("media", v)) }
        return a
    }
}

extension Track: HTMLVoidElement {
    var htmlTagName: String { "track" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("src", src)]
        if let v = kind { a.append(("kind", v.rawValue)) }
        if let v = label { a.append(("label", v)) }
        if let v = languageCode { a.append(("srclang", v)) }
        if isDefault { a.append(("default", "")) }
        return a
    }
}

extension Audio: HTMLContainerElement {
    var htmlTagName: String { "audio" }
    var htmlAttributes: [(String, String)] {
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
    var htmlTagName: String { "video" }
    var htmlAttributes: [(String, String)] {
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
    var htmlTagName: String { "picture" }
}

extension Canvas: HTMLContainerElement {
    var htmlTagName: String { "canvas" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        return a
    }
}
