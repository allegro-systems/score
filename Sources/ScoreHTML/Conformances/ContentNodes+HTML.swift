import ScoreCore

extension Heading: HTMLContainerElement {
    package var htmlTagName: String { "h\(level.rawValue)" }
}

extension Paragraph: HTMLContainerElement {
    package var htmlTagName: String { "p" }
}

extension Text: HTMLTransparentElement {}

extension Strong: HTMLContainerElement {
    package var htmlTagName: String { "strong" }
}

extension Emphasis: HTMLContainerElement {
    package var htmlTagName: String { "em" }
}

extension Small: HTMLContainerElement {
    package var htmlTagName: String { "small" }
}

extension Mark: HTMLContainerElement {
    package var htmlTagName: String { "mark" }
}

extension Code: HTMLContainerElement {
    package var htmlTagName: String { "code" }
}

extension Preformatted: HTMLContainerElement {
    package var htmlTagName: String { "pre" }
}

extension Blockquote: HTMLContainerElement {
    package var htmlTagName: String { "blockquote" }
}

extension Address: HTMLContainerElement {
    package var htmlTagName: String { "address" }
}

extension HorizontalRule: HTMLVoidElement {
    package var htmlTagName: String { "hr" }
}

extension LineBreak: HTMLVoidElement {
    package var htmlTagName: String { "br" }
}
