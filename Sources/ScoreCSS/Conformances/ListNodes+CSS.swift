import ScoreCore

extension UnorderedList: CSSContainerNode {
    var htmlTag: String? { "ul" }
}
extension OrderedList: CSSContainerNode {
    var htmlTag: String? { "ol" }
}
extension ListItem: CSSContainerNode {
    var htmlTag: String? { "li" }
}
extension DescriptionList: CSSContainerNode {
    var htmlTag: String? { "dl" }
}
extension DescriptionTerm: CSSContainerNode {
    var htmlTag: String? { "dt" }
}
extension DescriptionDetails: CSSContainerNode {
    var htmlTag: String? { "dd" }
}
