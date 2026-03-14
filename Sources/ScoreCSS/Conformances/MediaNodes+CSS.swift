import ScoreCore

extension Image: CSSLeafNode {
    package var htmlTag: String? { "img" }
}
extension Figure: CSSContainerNode {
    package var htmlTag: String? { "figure" }
}
extension FigureCaption: CSSContainerNode {
    package var htmlTag: String? { "figcaption" }
}
extension Source: CSSLeafNode {
    package var htmlTag: String? { "source" }
}
extension Track: CSSLeafNode {
    package var htmlTag: String? { "track" }
}
extension Audio: CSSContainerNode {
    package var htmlTag: String? { "audio" }
}
extension Video: CSSContainerNode {
    package var htmlTag: String? { "video" }
}
extension Picture: CSSContainerNode {
    package var htmlTag: String? { "picture" }
}
extension Canvas: CSSContainerNode {
    package var htmlTag: String? { "canvas" }
}
