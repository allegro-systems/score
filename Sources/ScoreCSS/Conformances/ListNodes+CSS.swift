import ScoreCore

extension UnorderedList: CSSContainerNode {
    package var htmlTag: String? { "ul" }
}
extension OrderedList: CSSContainerNode {
    package var htmlTag: String? { "ol" }
}
extension ListItem: CSSContainerNode {
    package var htmlTag: String? { "li" }
}
extension DescriptionList: CSSContainerNode {
    package var htmlTag: String? { "dl" }
}
extension DescriptionTerm: CSSContainerNode {
    package var htmlTag: String? { "dt" }
}
extension DescriptionDetails: CSSContainerNode {
    package var htmlTag: String? { "dd" }
}
