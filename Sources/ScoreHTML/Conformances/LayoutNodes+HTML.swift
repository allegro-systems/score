import ScoreCore

extension Stack: HTMLContainerElement {
    package var htmlTagName: String { "div" }
}

extension Main: HTMLContainerElement {
    package var htmlTagName: String { "main" }
}

extension Section: HTMLContainerElement {
    package var htmlTagName: String { "section" }
}

extension Article: HTMLContainerElement {
    package var htmlTagName: String { "article" }
}

extension Header: HTMLContainerElement {
    package var htmlTagName: String { "header" }
}

extension Footer: HTMLContainerElement {
    package var htmlTagName: String { "footer" }
}

extension Aside: HTMLContainerElement {
    package var htmlTagName: String { "aside" }
}

extension Navigation: HTMLContainerElement {
    package var htmlTagName: String { "nav" }
}

extension Group: HTMLTransparentElement {}
