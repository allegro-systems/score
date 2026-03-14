import ScoreCore

extension UnorderedList: HTMLContainerElement {
    package var htmlTagName: String { "ul" }
}

extension OrderedList: HTMLContainerElement {
    package var htmlTagName: String { "ol" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = start { a.append(("start", String(v))) }
        if isReversed { a.append(("reversed", "")) }
        return a
    }
}

extension ListItem: HTMLContainerElement {
    package var htmlTagName: String { "li" }
}

extension DescriptionList: HTMLContainerElement {
    package var htmlTagName: String { "dl" }
}

extension DescriptionTerm: HTMLContainerElement {
    package var htmlTagName: String { "dt" }
}

extension DescriptionDetails: HTMLContainerElement {
    package var htmlTagName: String { "dd" }
}
