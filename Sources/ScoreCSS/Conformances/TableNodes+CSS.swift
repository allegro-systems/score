import ScoreCore

extension Table: CSSContainerNode {
    var htmlTag: String? { "table" }
}
extension TableCaption: CSSContainerNode {
    var htmlTag: String? { "caption" }
}
extension TableHead: CSSContainerNode {
    var htmlTag: String? { "thead" }
}
extension TableBody: CSSContainerNode {
    var htmlTag: String? { "tbody" }
}
extension TableFooter: CSSContainerNode {
    var htmlTag: String? { "tfoot" }
}
extension TableRow: CSSContainerNode {
    var htmlTag: String? { "tr" }
}
extension TableHeaderCell: CSSContainerNode {
    var htmlTag: String? { "th" }
}
extension TableCell: CSSContainerNode {
    var htmlTag: String? { "td" }
}
extension TableColumnGroup: CSSContainerNode {
    var htmlTag: String? { "colgroup" }
}
extension TableColumn: CSSLeafNode {
    var htmlTag: String? { "col" }
}
