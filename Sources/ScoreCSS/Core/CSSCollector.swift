import ScoreCore

/// Collects CSS declarations from a node tree and deduplicates identical
/// rule sets to produce minimal output.
///
/// `CSSCollector` walks a node tree, extracts modifier values from
/// `ModifiedNode` instances, converts them to CSS declarations via
/// `CSSEmitter`, and groups the results by a content-derived scope
/// identifier. When two nodes produce identical declaration sets, they
/// share the same scope class, eliminating duplicate CSS.
///
/// ### Example
///
/// ```swift
/// var collector = CSSCollector()
/// collector.collect(from: myNodeTree)
/// let css = collector.renderStylesheet()
/// ```
///
/// ### Scope Deduplication
///
/// Each unique set of declarations is assigned a deterministic class name
/// derived from a hash of the sorted declarations. Nodes that happen to
/// produce the same CSS share the same class, keeping the stylesheet
/// compact.
public struct CSSCollector: Sendable {

    /// A rule set mapping a generated scope class name to its declarations.
    public struct Rule: Sendable, Hashable {

        /// The generated CSS class name for this scope (e.g. `"s-a1b2c3"`).
        public let className: String

        /// The CSS declarations that form this rule's body.
        public let declarations: [CSSDeclaration]
    }

    private var rules: [String: Rule] = [:]
    private var order: [String] = []

    /// Creates an empty collector.
    public init() {}

    /// Extracts CSS from a node tree and registers deduplicated rules.
    ///
    /// Walks the tree recursively. When a `ModifiedNode` is encountered,
    /// its modifier values are converted to CSS declarations and
    /// registered as a scoped rule.
    ///
    /// - Parameter node: The root node to collect CSS from.
    public mutating func collect(from node: some Node) {
        walk(node)
    }

    /// Returns all collected rules in document order.
    ///
    /// Rules appear in the order their scope class was first encountered
    /// during tree traversal.
    ///
    /// - Returns: An ordered array of deduplicated CSS rules.
    public func collectedRules() -> [Rule] {
        order.compactMap { rules[$0] }
    }

    /// Renders the collected rules as a CSS stylesheet string.
    ///
    /// Each rule is rendered as a class selector with its declarations.
    /// Rules are separated by newlines for readability.
    ///
    /// - Returns: A complete CSS stylesheet string.
    public func renderStylesheet() -> String {
        var output = ""
        for className in order {
            guard let rule = rules[className] else { continue }
            output.append(".\(rule.className) {\n")
            for declaration in rule.declarations {
                output.append("  \(declaration.render());\n")
            }
            output.append("}\n")
        }
        return output
    }

    // MARK: - Tree Walking

    private mutating func walk(_ node: some Node) {
        if let modified = node as? any _NodeContainingModifiers {
            registerModifiers(modified.modifiers)
            modified.collectChildCSS(into: &self)
            return
        }

        if let walkable = node as? any CSSWalkable {
            walkable.walkChildren(collector: &self)
            return
        }

        walk(node.body)
    }

    private mutating func registerModifiers(_ modifiers: [any ModifierValue]) {
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }
        guard !declarations.isEmpty else { return }

        let className = scopeClassName(for: declarations)
        if rules[className] == nil {
            rules[className] = Rule(className: className, declarations: declarations)
            order.append(className)
        }
    }

    private func scopeClassName(for declarations: [CSSDeclaration]) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for d in declarations {
            for byte in d.property.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
            for byte in d.value.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }
        return "s-\(String(hash, radix: 36))"
    }
}

// MARK: - _NodeContainingModifiers

/// Internal protocol that allows `CSSCollector` to detect and descend into
/// `ModifiedNode` without triggering the "some types are only permitted in
/// properties, subscripts, and functions" compiler error.
protocol _NodeContainingModifiers {
    var modifiers: [any ModifierValue] { get }
    func collectChildCSS(into collector: inout CSSCollector)
}

extension ModifiedNode: _NodeContainingModifiers {
    func collectChildCSS(into collector: inout CSSCollector) {
        collector.collect(from: content)
    }
}

// MARK: - CSSWalkable

/// A node that can expose its children for CSS collection.
///
/// All primitive node types (those with `body: Never`) conform to
/// `CSSWalkable` so that `CSSCollector` can traverse them without calling
/// `body`, which would trap at runtime for primitive nodes.
protocol CSSWalkable {
    func walkChildren(collector: inout CSSCollector)
}

// MARK: - CSSContainerNode

/// A container node whose single `content` child should be walked for CSS.
///
/// Conforming to this protocol provides a default `walkChildren` that calls
/// `collector.collect(from: content)`, eliminating per-type boilerplate.
protocol CSSContainerNode: CSSWalkable {
    associatedtype Content: Node
    var content: Content { get }
}

extension CSSContainerNode {
    func walkChildren(collector: inout CSSCollector) {
        collector.collect(from: content)
    }
}

// MARK: - CSSLeafNode

/// A leaf node with no children to walk for CSS collection.
///
/// Conforming to this protocol provides an empty `walkChildren` default.
protocol CSSLeafNode: CSSWalkable {}

extension CSSLeafNode {
    func walkChildren(collector: inout CSSCollector) {}
}
