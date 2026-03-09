import ScoreCore

extension Table: HTMLContainerElement {
    var htmlTagName: String { "table" }
}

extension TableCaption: HTMLContainerElement {
    var htmlTagName: String { "caption" }
}

extension TableHead: HTMLContainerElement {
    var htmlTagName: String { "thead" }
}

extension TableBody: HTMLContainerElement {
    var htmlTagName: String { "tbody" }
}

extension TableFooter: HTMLContainerElement {
    var htmlTagName: String { "tfoot" }
}

extension TableRow: HTMLContainerElement {
    var htmlTagName: String { "tr" }
}

extension TableHeaderCell: HTMLContainerElement {
    var htmlTagName: String { "th" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = scope { a.append(("scope", v.rawValue)) }
        return a
    }
}

extension TableCell: HTMLContainerElement {
    var htmlTagName: String { "td" }
}

extension TableColumnGroup: HTMLContainerElement {
    var htmlTagName: String { "colgroup" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = span { a.append(("span", String(v))) }
        return a
    }
}

extension TableColumn: HTMLVoidElement {
    var htmlTagName: String { "col" }
    var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = span { a.append(("span", String(v))) }
        return a
    }
}
