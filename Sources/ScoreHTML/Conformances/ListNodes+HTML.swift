import ScoreCore

extension UnorderedList: HTMLContainerElement {
    var htmlTagName: String { "ul" }
}

extension OrderedList: HTMLContainerElement {
    var htmlTagName: String { "ol" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = start { a.append(("start", String(v))) }
        if isReversed { a.append(("reversed", "")) }
        return a
    }
}

extension ListItem: HTMLContainerElement {
    var htmlTagName: String { "li" }
}

extension DescriptionList: HTMLContainerElement {
    var htmlTagName: String { "dl" }
}

extension DescriptionTerm: HTMLContainerElement {
    var htmlTagName: String { "dt" }
}

extension DescriptionDetails: HTMLContainerElement {
    var htmlTagName: String { "dd" }
}
