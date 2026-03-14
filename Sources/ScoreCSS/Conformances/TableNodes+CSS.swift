import ScoreCore

extension Table: CSSContainerNode {
    package var htmlTag: String? { "table" }
}
extension TableCaption: CSSContainerNode {
    package var htmlTag: String? { "caption" }
}
extension TableHead: CSSContainerNode {
    package var htmlTag: String? { "thead" }
}
extension TableBody: CSSContainerNode {
    package var htmlTag: String? { "tbody" }
}
extension TableFooter: CSSContainerNode {
    package var htmlTag: String? { "tfoot" }
}
extension TableRow: CSSContainerNode {
    package var htmlTag: String? { "tr" }
}
extension TableHeaderCell: CSSContainerNode {
    package var htmlTag: String? { "th" }
}
extension TableCell: CSSContainerNode {
    package var htmlTag: String? { "td" }
}
extension TableColumnGroup: CSSContainerNode {
    package var htmlTag: String? { "colgroup" }
}
extension TableColumn: CSSLeafNode {
    package var htmlTag: String? { "col" }
}
