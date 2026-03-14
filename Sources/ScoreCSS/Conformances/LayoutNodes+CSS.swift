import ScoreCore

extension Stack: CSSContainerNode {
    package var htmlTag: String? { "div" }
}
extension Main: CSSContainerNode {
    package var htmlTag: String? { "main" }
}
extension Section: CSSContainerNode {
    package var htmlTag: String? { "section" }
}
extension Article: CSSContainerNode {
    package var htmlTag: String? { "article" }
}
extension Header: CSSContainerNode {
    package var htmlTag: String? { "header" }
}
extension Footer: CSSContainerNode {
    package var htmlTag: String? { "footer" }
}
extension Aside: CSSContainerNode {
    package var htmlTag: String? { "aside" }
}
extension Navigation: CSSContainerNode {
    package var htmlTag: String? { "nav" }
}
extension Group: CSSContainerNode {}
