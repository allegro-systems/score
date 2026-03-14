import ScoreCore

extension Heading: CSSContainerNode {
    package var htmlTag: String? { "h\(level.rawValue)" }
}
extension Paragraph: CSSContainerNode {
    package var htmlTag: String? { "p" }
}
extension Text: CSSContainerNode {}
extension Strong: CSSContainerNode {
    package var htmlTag: String? { "strong" }
}
extension Emphasis: CSSContainerNode {
    package var htmlTag: String? { "em" }
}
extension Small: CSSContainerNode {
    package var htmlTag: String? { "small" }
}
extension Mark: CSSContainerNode {
    package var htmlTag: String? { "mark" }
}
extension Code: CSSContainerNode {
    package var htmlTag: String? { "code" }
}
extension Preformatted: CSSContainerNode {
    package var htmlTag: String? { "pre" }
}
extension Blockquote: CSSContainerNode {
    package var htmlTag: String? { "blockquote" }
}
extension Address: CSSContainerNode {
    package var htmlTag: String? { "address" }
}
extension HorizontalRule: CSSLeafNode {
    package var htmlTag: String? { "hr" }
}
extension LineBreak: CSSLeafNode {
    package var htmlTag: String? { "br" }
}
