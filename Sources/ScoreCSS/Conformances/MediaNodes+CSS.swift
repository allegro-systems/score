import ScoreCore

extension Image: CSSLeafNode {
    var htmlTag: String? { "img" }
}
extension Figure: CSSContainerNode {
    var htmlTag: String? { "figure" }
}
extension FigureCaption: CSSContainerNode {
    var htmlTag: String? { "figcaption" }
}
extension Source: CSSLeafNode {
    var htmlTag: String? { "source" }
}
extension Track: CSSLeafNode {
    var htmlTag: String? { "track" }
}
extension Audio: CSSContainerNode {
    var htmlTag: String? { "audio" }
}
extension Video: CSSContainerNode {
    var htmlTag: String? { "video" }
}
extension Picture: CSSContainerNode {
    var htmlTag: String? { "picture" }
}
extension Canvas: CSSContainerNode {
    var htmlTag: String? { "canvas" }
}
