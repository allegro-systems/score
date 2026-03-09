import ScoreCore

extension Link: CSSContainerNode {}
extension Dialog: CSSContainerNode {}
extension Menu: CSSContainerNode {}
extension Summary: CSSContainerNode {}

/// Details has dual children (summary + content) requiring custom walking.
extension Details: CSSWalkable {
    func walkChildren(collector: inout CSSCollector) {
        collector.collect(from: summary)
        collector.collect(from: content)
    }
}
