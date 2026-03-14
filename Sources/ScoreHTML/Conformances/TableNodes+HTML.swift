import ScoreCore

extension Table: HTMLContainerElement {
    package var htmlTagName: String { "table" }
}

extension TableCaption: HTMLContainerElement {
    package var htmlTagName: String { "caption" }
}

extension TableHead: HTMLContainerElement {
    package var htmlTagName: String { "thead" }
}

extension TableBody: HTMLContainerElement {
    package var htmlTagName: String { "tbody" }
}

extension TableFooter: HTMLContainerElement {
    package var htmlTagName: String { "tfoot" }
}

extension TableRow: HTMLContainerElement {
    package var htmlTagName: String { "tr" }
}

extension TableHeaderCell: HTMLContainerElement {
    package var htmlTagName: String { "th" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = scope { a.append(("scope", v.rawValue)) }
        return a
    }
}

extension TableCell: HTMLContainerElement {
    package var htmlTagName: String { "td" }
}

extension TableColumnGroup: HTMLContainerElement {
    package var htmlTagName: String { "colgroup" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = span { a.append(("span", String(v))) }
        return a
    }
}

extension TableColumn: HTMLVoidElement {
    package var htmlTagName: String { "col" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = span { a.append(("span", String(v))) }
        return a
    }
}
