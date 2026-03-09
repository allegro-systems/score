import ScoreCore

extension Stack: CSSContainerNode {
    var htmlTag: String? { "div" }
}
extension Main: CSSContainerNode {
    var htmlTag: String? { "main" }
}
extension Section: CSSContainerNode {
    var htmlTag: String? { "section" }
}
extension Article: CSSContainerNode {
    var htmlTag: String? { "article" }
}
extension Header: CSSContainerNode {
    var htmlTag: String? { "header" }
}
extension Footer: CSSContainerNode {
    var htmlTag: String? { "footer" }
}
extension Aside: CSSContainerNode {
    var htmlTag: String? { "aside" }
}
extension Navigation: CSSContainerNode {
    var htmlTag: String? { "nav" }
}
extension Group: CSSContainerNode {}
