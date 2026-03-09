import ScoreCore

extension Heading: HTMLContainerElement {
    var htmlTagName: String { "h\(level.rawValue)" }
}

extension Paragraph: HTMLContainerElement {
    var htmlTagName: String { "p" }
}

extension Text: HTMLTransparentElement {}

extension Strong: HTMLContainerElement {
    var htmlTagName: String { "strong" }
}

extension Emphasis: HTMLContainerElement {
    var htmlTagName: String { "em" }
}

extension Small: HTMLContainerElement {
    var htmlTagName: String { "small" }
}

extension Mark: HTMLContainerElement {
    var htmlTagName: String { "mark" }
}

extension Code: HTMLContainerElement {
    var htmlTagName: String { "code" }
}

extension Preformatted: HTMLContainerElement {
    var htmlTagName: String { "pre" }
}

extension Blockquote: HTMLContainerElement {
    var htmlTagName: String { "blockquote" }
}

extension Address: HTMLContainerElement {
    var htmlTagName: String { "address" }
}

extension HorizontalRule: HTMLVoidElement {
    var htmlTagName: String { "hr" }
}

extension LineBreak: HTMLVoidElement {
    var htmlTagName: String { "br" }
}
