import ScoreCore

/// Renders as the `<img>` void element.
extension Image: HTMLRenderable {
    /// Emits a self-closing `<img>` with `src`, `alt`, and optional `width`, `height`, `loading`, and `decoding`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("src", src), ("alt", alt)]
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        if let v = loading { a.append(("loading", v.rawValue)) }
        if let v = decoding { a.append(("decoding", v.rawValue)) }
        renderer.voidTag("img", a, to: &output)
    }
}

/// Renders as a `<figure>` self-contained content element.
extension Figure: HTMLRenderable {
    /// Wraps content in a `<figure>` element.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.tag("figure", content: content, to: &output)
    }
}

/// Renders as a `<figcaption>` caption for a `<figure>`.
extension FigureCaption: HTMLRenderable {
    /// Wraps content in a `<figcaption>` element.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.tag("figcaption", content: content, to: &output)
    }
}

/// Renders as the `<source>` void element specifying a media resource.
extension Source: HTMLRenderable {
    /// Emits a self-closing `<source>` with `src` and optional `type` and `media` attributes.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("src", src)]
        if let v = type { a.append(("type", v)) }
        if let v = media { a.append(("media", v)) }
        renderer.voidTag("source", a, to: &output)
    }
}

/// Renders as the `<track>` void element for timed text tracks.
extension Track: HTMLRenderable {
    /// Emits a self-closing `<track>` with `src` and optional `kind`, `label`, `srclang`, and `default`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("src", src)]
        if let v = kind { a.append(("kind", v.rawValue)) }
        if let v = label { a.append(("label", v)) }
        if let v = languageCode { a.append(("srclang", v)) }
        if isDefault { a.append(("default", "")) }
        renderer.voidTag("track", a, to: &output)
    }
}

/// Renders as an `<audio>` embedded audio element.
extension Audio: HTMLRenderable {
    /// Emits an `<audio>` with optional `src`, `controls`, `autoplay`, `loop`, `muted`, and `preload`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = src { a.append(("src", v)) }
        if controls { a.append(("controls", "")) }
        if autoplay { a.append(("autoplay", "")) }
        if loop { a.append(("loop", "")) }
        if muted { a.append(("muted", "")) }
        if let v = preload { a.append(("preload", v.rawValue)) }
        renderer.tag("audio", a, content: content, to: &output)
    }
}

/// Renders as a `<video>` embedded video element.
extension Video: HTMLRenderable {
    /// Emits a `<video>` with optional `src`, `controls`, `autoplay`, `loop`, `muted`, `preload`, `poster`, `width`, and `height`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = src { a.append(("src", v)) }
        if controls { a.append(("controls", "")) }
        if autoplay { a.append(("autoplay", "")) }
        if loop { a.append(("loop", "")) }
        if muted { a.append(("muted", "")) }
        if let v = preload { a.append(("preload", v.rawValue)) }
        if let v = poster { a.append(("poster", v)) }
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        renderer.tag("video", a, content: content, to: &output)
    }
}

/// Renders as a `<picture>` responsive image container.
extension Picture: HTMLRenderable {
    /// Wraps content in a `<picture>` element.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.tag("picture", content: content, to: &output)
    }
}

/// Renders as a `<canvas>` bitmap drawing surface.
extension Canvas: HTMLRenderable {
    /// Emits a `<canvas>` with optional `width` and `height` attributes.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = width { a.append(("width", String(v))) }
        if let v = height { a.append(("height", String(v))) }
        renderer.tag("canvas", a, content: content, to: &output)
    }
}
