import ScoreCore

/// Leaf node — no children to walk.
extension EmptyNode: CSSWalkable {
    /// No-op; `EmptyNode` contains no children.
    func walkChildren(collector: inout CSSCollector) {}
}

/// Leaf node — text content carries no CSS modifiers.
extension TextNode: CSSWalkable {
    /// No-op; `TextNode` contains no child nodes.
    func walkChildren(collector: inout CSSCollector) {}
}

/// Leaf node — raw text carries no CSS modifiers.
extension RawTextNode: CSSWalkable {
    /// No-op; `RawTextNode` contains no child nodes.
    func walkChildren(collector: inout CSSCollector) {}
}

/// Walks all children via parameter pack expansion.
extension TupleNode: CSSWalkable {
    /// Collects CSS from each child using `repeat each children`.
    func walkChildren(collector: inout CSSCollector) {
        repeat collector.collect(from: each children)
    }
}

/// Walks the active branch of an `if`/`else` builder expression.
extension ConditionalNode: CSSWalkable {
    /// Collects CSS from whichever branch — `.first` or `.second` — was chosen at build time.
    func walkChildren(collector: inout CSSCollector) {
        switch storage {
        case .first(let node): collector.collect(from: node)
        case .second(let node): collector.collect(from: node)
        }
    }
}

/// Walks the wrapped node when present.
extension OptionalNode: CSSWalkable {
    /// Collects CSS from the wrapped node if non-nil; otherwise no-op.
    func walkChildren(collector: inout CSSCollector) {
        if let node = wrapped { collector.collect(from: node) }
    }
}

/// Walks every item produced by a data-driven loop.
extension ForEachNode: CSSWalkable {
    /// Iterates `data`, collecting CSS from `content(item)` for each element.
    func walkChildren(collector: inout CSSCollector) {
        for item in data { collector.collect(from: content(item)) }
    }
}

/// Walks a runtime array of heterogeneous children.
extension ArrayNode: CSSWalkable {
    /// Collects CSS from each child node in order.
    func walkChildren(collector: inout CSSCollector) {
        for item in children { collector.collect(from: item) }
    }
}
