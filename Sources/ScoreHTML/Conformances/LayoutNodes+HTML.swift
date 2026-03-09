import ScoreCore

extension Stack: HTMLContainerElement {
    var htmlTagName: String { "div" }
}

extension Main: HTMLContainerElement {
    var htmlTagName: String { "main" }
}

extension Section: HTMLContainerElement {
    var htmlTagName: String { "section" }
}

extension Article: HTMLContainerElement {
    var htmlTagName: String { "article" }
}

extension Header: HTMLContainerElement {
    var htmlTagName: String { "header" }
}

extension Footer: HTMLContainerElement {
    var htmlTagName: String { "footer" }
}

extension Aside: HTMLContainerElement {
    var htmlTagName: String { "aside" }
}

extension Navigation: HTMLContainerElement {
    var htmlTagName: String { "nav" }
}

extension Group: HTMLTransparentElement {}
