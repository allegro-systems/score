import ScoreCore

extension Link: CSSContainerNode {
    package var htmlTag: String? { "a" }
}
extension Dialog: CSSContainerNode {
    package var htmlTag: String? { "dialog" }
}
extension Menu: CSSContainerNode {
    package var htmlTag: String? { "menu" }
}
extension Summary: CSSContainerNode {
    package var htmlTag: String? { "summary" }
}

/// Details has dual children (summary + content) requiring custom walking.
extension Details: CSSWalkable {
    package var htmlTag: String? { "details" }
    package func walkChildren(collector: inout CSSCollector) {
        collector.collect(from: summary)
        collector.collect(from: content)
    }
}
