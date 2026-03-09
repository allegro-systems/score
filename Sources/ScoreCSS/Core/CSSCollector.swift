import ScoreCore

/// Collects CSS declarations from a node tree, flattens modifier chains,
/// tracks component scopes, and produces nested CSS output.
///
/// `CSSCollector` walks a node tree, flattening chained `ModifiedNode`
/// wrappers into single entries with their rendering context (component
/// scope and inner HTML tag). The collected entries are then analyzed to
/// produce CSS with nesting under component selectors where possible.
///
/// ### CSS Nesting Strategy
///
/// When a modifier set appears inside a component and wraps an element
/// with a unique HTML tag within that component, the CSS rule is emitted
/// as a nested element selector:
///
/// ```css
/// .feature-card {
///   article { padding: 20px; background: ...; }
///   h3 { font-size: 17px; }
/// }
/// ```
///
/// When the same tag appears multiple times with different styles, or when
/// there is no component scope, semantic class names are generated instead.
///
/// ### Example
///
/// ```swift
/// var collector = CSSCollector()
/// collector.pageName = "home"
/// collector.collect(from: myNodeTree)
/// let result = collector.renderStylesheet()
/// // result.css — the stylesheet string
/// // result.classLookup — declaration key → class name
/// // result.nestedKeys — declaration keys handled by CSS nesting
/// ```
public struct CSSCollector: Sendable {

    /// The result of stylesheet generation, containing the CSS string and
    /// the class mapping information needed by the HTML renderer.
    public struct StylesheetResult: Sendable {
        /// The rendered CSS string with nested component rules.
        public let css: String
        /// Maps declaration keys to CSS class names for entries that need
        /// a class attribute in the HTML output.
        public let classLookup: [String: String]
        /// Declaration keys handled by CSS nesting (no class needed in HTML).
        public let nestedKeys: Set<String>
    }

    /// A rule set mapping a class name to its declarations (backward compat).
    public struct Rule: Sendable, Hashable {
        /// The generated CSS class name.
        public let className: String
        /// The CSS declarations that form this rule's body.
        public let declarations: [CSSDeclaration]
    }

    /// A collected entry recording a flattened modifier set with its context.
    private struct Entry: Sendable {
        let declarations: [CSSDeclaration]
        let declarationKey: String
        let fingerprint: String
        let componentScope: String?
        let htmlTag: String?
    }

    private var entries: [Entry] = []
    private var seenEntries: Set<String> = []
    private var componentStack: [String] = []

    /// The page name used as the base for flat class names when no
    /// component scope is active.
    public var pageName: String?

    /// Creates an empty collector.
    public init() {}

    /// Extracts CSS from a node tree, flattening modifier chains and
    /// tracking component scopes.
    ///
    /// - Parameter node: The root node to collect CSS from.
    public mutating func collect(from node: some Node) {
        walk(node)
    }

    // MARK: - Output

    /// Analyzes collected entries and renders the stylesheet with CSS nesting.
    ///
    /// Entries inside a component scope with a unique HTML tag are rendered
    /// as nested element selectors. Ambiguous or scope-less entries receive
    /// semantic class names.
    ///
    /// - Returns: A `StylesheetResult` containing the CSS, class lookup, and
    ///   set of declaration keys handled by nesting.
    public func renderStylesheet() -> StylesheetResult {
        // Group entries by component scope
        var componentGroups: [(scope: String, entries: [Entry])] = []
        var componentIndex: [String: Int] = [:]
        var flatEntries: [Entry] = []

        for entry in entries {
            if let scope = entry.componentScope {
                if let idx = componentIndex[scope] {
                    componentGroups[idx].entries.append(entry)
                } else {
                    componentIndex[scope] = componentGroups.count
                    componentGroups.append((scope, [entry]))
                }
            } else {
                flatEntries.append(entry)
            }
        }

        var css = ""
        var classLookup: [String: String] = [:]
        var nestedKeys: Set<String> = []

        // Render component groups with CSS nesting
        for (scope, groupEntries) in componentGroups {
            // Detect ambiguity: same tag with different fingerprints
            var tagFingerprints: [String: Set<String>] = [:]
            for entry in groupEntries {
                guard let tag = entry.htmlTag else { continue }
                tagFingerprints[tag, default: []].insert(entry.fingerprint)
            }
            let ambiguousTags = Set(tagFingerprints.filter { $0.value.count > 1 }.keys)

            css.append(".\(scope) {\n")

            var tagOrdinals: [String: Int] = [:]

            for entry in groupEntries {
                let decls = renderDeclarations(entry.declarations)

                if let tag = entry.htmlTag, !ambiguousTags.contains(tag) {
                    // Unique tag within component → nested element selector
                    css.append("  \(tag) { \(decls) }\n")
                    nestedKeys.insert(entry.declarationKey)
                } else {
                    // Ambiguous tag or no tag → named class nested under component
                    let tagKey = entry.htmlTag ?? "div"
                    let ordinal = (tagOrdinals[tagKey] ?? 0) + 1
                    tagOrdinals[tagKey] = ordinal
                    let className = Self.semanticClassName(
                        component: scope,
                        tag: entry.htmlTag,
                        pageName: pageName,
                        ordinal: ordinal
                    )
                    css.append("  .\(className) { \(decls) }\n")
                    classLookup[entry.declarationKey] = className
                }
            }

            css.append("}\n")
        }

        // Render flat entries (no component scope)
        var flatTagOrdinals: [String: Int] = [:]
        for entry in flatEntries {
            let tagKey = entry.htmlTag ?? "div"
            let ordinal = (flatTagOrdinals[tagKey] ?? 0) + 1
            flatTagOrdinals[tagKey] = ordinal
            let className = Self.semanticClassName(
                component: nil,
                tag: entry.htmlTag,
                pageName: pageName,
                ordinal: ordinal
            )
            let decls = renderDeclarations(entry.declarations)
            css.append(".\(className) { \(decls) }\n")
            classLookup[entry.declarationKey] = className
        }

        return StylesheetResult(css: css, classLookup: classLookup, nestedKeys: nestedKeys)
    }

    /// Returns all collected entries as flat rules for backward compatibility.
    ///
    /// Entries are deduplicated by declaration fingerprint and assigned
    /// sequential class names.
    public func collectedRules() -> [Rule] {
        var seen: [String: Rule] = [:]
        var order: [String] = []
        var nextIndex = 0

        for entry in entries {
            if seen[entry.fingerprint] == nil {
                seen[entry.fingerprint] = Rule(
                    className: "s-\(nextIndex)",
                    declarations: entry.declarations
                )
                order.append(entry.fingerprint)
                nextIndex += 1
            }
        }

        return order.compactMap { seen[$0] }
    }

    // MARK: - Tree Walking

    private mutating func walk(_ node: some Node) {
        // 1. Modified node → flatten chain and register combined modifiers
        if let modified = node as? any ModifierContaining {
            let (allModifiers, innerNode) = flattenChain(modified)
            let tag = (innerNode as? any CSSWalkable)?.htmlTag
            registerModifiers(allModifiers, htmlTag: tag)
            // Walk inner content for its children's CSS
            collect(from: innerNode)
            return
        }

        // 2. CSS primitive → walk children directly
        if let walkable = node as? any CSSWalkable {
            walkable.walkChildren(collector: &self)
            return
        }

        // 3. Composite node → detect Component scope
        if node is any Component {
            let name = CSSNaming.className(from: String(describing: type(of: node)))
            componentStack.append(name)
            collect(from: node.body)
            componentStack.removeLast()
        } else {
            collect(from: node.body)
        }
    }

    private func flattenChain(_ modified: any ModifierContaining) -> ([any ModifierValue], any Node) {
        var allModifiers = modified.modifiers
        var current = modified.innerContent
        while let inner = current as? any ModifierContaining {
            allModifiers.append(contentsOf: inner.modifiers)
            current = inner.innerContent
        }
        return (allModifiers, current)
    }

    private mutating func registerModifiers(_ modifiers: [any ModifierValue], htmlTag: String?) {
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }
        guard !declarations.isEmpty else { return }

        let fingerprint = declarationFingerprint(for: declarations)
        let scope = componentStack.last
        let dedupKey = "\(scope ?? "")|\(htmlTag ?? "")|\(fingerprint)"

        guard !seenEntries.contains(dedupKey) else { return }
        seenEntries.insert(dedupKey)

        let declarationKey = declarations.map { "\($0.property):\($0.value)" }.joined(separator: ";")
        entries.append(Entry(
            declarations: declarations,
            declarationKey: declarationKey,
            fingerprint: fingerprint,
            componentScope: scope,
            htmlTag: htmlTag
        ))
    }

    // MARK: - Helpers

    private func renderDeclarations(_ declarations: [CSSDeclaration]) -> String {
        declarations.map { "\($0.render());" }.joined(separator: " ")
    }

    /// Generates a semantic class name from component, tag, and ordinal context.
    static func semanticClassName(
        component: String?,
        tag: String?,
        pageName: String?,
        ordinal: Int
    ) -> String {
        let tagName = friendlyTagName(tag ?? "div")
        let base = component ?? pageName ?? "scope"
        let name = "\(base)-\(tagName)"
        return ordinal > 1 ? "\(name)-\(ordinal)" : name
    }

    /// Maps HTML tag names to human-readable equivalents for class naming.
    static func friendlyTagName(_ tag: String) -> String {
        switch tag {
        case "h1", "h2", "h3", "h4", "h5", "h6": return "heading"
        case "p": return "text"
        case "a": return "link"
        case "div": return "stack"
        case "section": return "section"
        case "article": return "article"
        case "nav": return "nav"
        case "header": return "header"
        case "footer": return "footer"
        case "main": return "main"
        case "ul", "ol": return "list"
        case "button": return "button"
        case "img": return "image"
        case "small": return "small"
        default: return tag
        }
    }

    /// FNV-1a hash of declaration content, used as deduplication key.
    private func declarationFingerprint(for declarations: [CSSDeclaration]) -> String {
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
        return String(hash, radix: 36)
    }
}

// MARK: - ModifierContaining

/// A node that contains modifier values and can expose its inner content
/// for chain flattening and CSS collection.
protocol ModifierContaining {
    var modifiers: [any ModifierValue] { get }
    /// The inner content node, type-erased for chain flattening.
    var innerContent: any Node { get }
}

extension ModifiedNode: ModifierContaining {
    var innerContent: any Node { content }
}

// MARK: - CSSWalkable

/// A node that can expose its children for CSS collection.
///
/// All primitive node types (those with `body: Never`) conform to
/// `CSSWalkable` so that `CSSCollector` can traverse them without calling
/// `body`, which would trap at runtime for primitive nodes.
protocol CSSWalkable {
    /// The HTML tag this node renders as, used for CSS nesting selectors.
    /// Returns `nil` for nodes that don't emit a tag (e.g. `Group`, `Text`).
    var htmlTag: String? { get }
    func walkChildren(collector: inout CSSCollector)
}

extension CSSWalkable {
    var htmlTag: String? { nil }
}

// MARK: - CSSContainerNode

/// A container node whose single `content` child should be walked for CSS.
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
protocol CSSLeafNode: CSSWalkable {}

extension CSSLeafNode {
    func walkChildren(collector: inout CSSCollector) {}
}
