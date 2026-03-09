import ScoreCore

extension Heading: CSSContainerNode {
    var htmlTag: String? { "h\(level.rawValue)" }
}
extension Paragraph: CSSContainerNode {
    var htmlTag: String? { "p" }
}
extension Text: CSSContainerNode {}
extension Strong: CSSContainerNode {
    var htmlTag: String? { "strong" }
}
extension Emphasis: CSSContainerNode {
    var htmlTag: String? { "em" }
}
extension Small: CSSContainerNode {
    var htmlTag: String? { "small" }
}
extension Mark: CSSContainerNode {
    var htmlTag: String? { "mark" }
}
extension Code: CSSContainerNode {
    var htmlTag: String? { "code" }
}
extension Preformatted: CSSContainerNode {
    var htmlTag: String? { "pre" }
}
extension Blockquote: CSSContainerNode {
    var htmlTag: String? { "blockquote" }
}
extension Address: CSSContainerNode {
    var htmlTag: String? { "address" }
}
extension HorizontalRule: CSSLeafNode {
    var htmlTag: String? { "hr" }
}
extension LineBreak: CSSLeafNode {
    var htmlTag: String? { "br" }
}
