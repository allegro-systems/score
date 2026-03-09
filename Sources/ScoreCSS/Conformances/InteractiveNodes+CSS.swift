import ScoreCore

extension Link: CSSContainerNode {
    var htmlTag: String? { "a" }
}
extension Dialog: CSSContainerNode {
    var htmlTag: String? { "dialog" }
}
extension Menu: CSSContainerNode {
    var htmlTag: String? { "menu" }
}
extension Summary: CSSContainerNode {
    var htmlTag: String? { "summary" }
}

/// Details has dual children (summary + content) requiring custom walking.
extension Details: CSSWalkable {
    var htmlTag: String? { "details" }
    func walkChildren(collector: inout CSSCollector) {
        collector.collect(from: summary)
        collector.collect(from: content)
    }
}
