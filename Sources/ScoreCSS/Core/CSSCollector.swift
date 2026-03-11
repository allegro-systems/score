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
///   article {
///     padding: 20px;
///     background: ...;
///   }
///   h3 {
///     font-size: 17px;
///   }
/// }
/// ```
///
/// When the same tag appears multiple times with different styles, or when
/// there is no component scope, semantic class names are generated instead.
///
/// Pseudo-class modifiers (e.g. `.hover(...)`) are nested inside their
/// parent element using the `&` selector:
///
/// ```css
/// .feature-card {
///   article {
///     padding: 20px;
///     &:hover {
///       background-color: oklch(0.12 0.01 60);
///     }
///   }
/// }
/// ```
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
        /// Per-component CSS blocks keyed by scope name, used for chunking
        /// shared component styles into a separate file during static builds.
        public let componentBlocks: [String: String]
        /// CSS for entries without a component scope.
        public let flatCSS: String
    }

    /// A rule set mapping a class name to its declarations (backward compat).
    public struct Rule: Sendable, Hashable {
        /// The generated CSS class name.
        public let className: String
        /// The CSS declarations that form this rule's body.
        public let declarations: [CSSDeclaration]
    }

    private struct PseudoEntry: Sendable {
        let pseudoClass: PseudoClass
        let declarations: [CSSDeclaration]
    }

    private struct Entry: Sendable {
        let declarations: [CSSDeclaration]
        let declarationKey: String
        let pseudoEntries: [PseudoEntry]
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
    /// semantic class names. Pseudo-class entries are emitted alongside their
    /// base rules using the same selector.
    ///
    /// - Returns: A `StylesheetResult` containing the CSS, class lookup, and
    ///   set of declaration keys handled by nesting.
    public func renderStylesheet() -> StylesheetResult {
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
        var componentBlocks: [String: String] = [:]

        for (scope, groupEntries) in componentGroups {
            var tagDeclarationKeys: [String: Set<String>] = [:]
            for entry in groupEntries where !entry.declarations.isEmpty {
                guard let tag = entry.htmlTag else { continue }
                tagDeclarationKeys[tag, default: []].insert(entry.declarationKey)
            }
            var ambiguousTags = Set(tagDeclarationKeys.filter { $0.value.count > 1 }.keys)
            ambiguousTags.formUnion(Self.alwaysClassedTags)

            var blockCSS = ".\(scope) {\n"

            var tagOrdinals: [String: Int] = [:]

            for entry in groupEntries {
                if !entry.declarations.isEmpty {
                    let decls = renderDeclarations(entry.declarations, indent: "    ")

                    if let tag = entry.htmlTag, !ambiguousTags.contains(tag) {
                        blockCSS.append("  \(tag) {\n\(decls)")
                        emitNestedPseudoRules(entry.pseudoEntries, indent: "    ", into: &blockCSS)
                        blockCSS.append("\n  }\n")
                        nestedKeys.insert(entry.declarationKey)
                    } else {
                        let tagKey = entry.htmlTag ?? "div"
                        let ordinal = (tagOrdinals[tagKey] ?? 0) + 1
                        tagOrdinals[tagKey] = ordinal
                        let className = Self.semanticClassName(
                            component: scope,
                            tag: entry.htmlTag,
                            pageName: pageName,
                            ordinal: ordinal
                        )
                        blockCSS.append("  .\(className) {\n\(decls)")
                        emitNestedPseudoRules(entry.pseudoEntries, indent: "    ", into: &blockCSS)
                        blockCSS.append("\n  }\n")
                        classLookup[entry.declarationKey] = className
                    }
                } else if let tag = entry.htmlTag {
                    blockCSS.append("  \(tag) {\n")
                    emitNestedPseudoRules(entry.pseudoEntries, indent: "    ", into: &blockCSS)
                    blockCSS.append("\n  }\n")
                }
            }

            blockCSS.append("}\n")
            componentBlocks[scope] = blockCSS
            css.append(blockCSS)
        }

        var flatCSS = ""
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

            if !entry.declarations.isEmpty {
                let decls = renderDeclarations(entry.declarations, indent: "  ")
                var rule = ".\(className) {\n\(decls)"
                emitNestedPseudoRules(entry.pseudoEntries, indent: "  ", into: &rule)
                rule.append("\n}\n")
                flatCSS.append(rule)
                css.append(rule)
                classLookup[entry.declarationKey] = className
            } else if !entry.pseudoEntries.isEmpty {
                var rule = ".\(className) {\n"
                emitNestedPseudoRules(entry.pseudoEntries, indent: "  ", into: &rule)
                rule.append("\n}\n")
                flatCSS.append(rule)
                css.append(rule)
            }
        }

        return StylesheetResult(
            css: css,
            classLookup: classLookup,
            nestedKeys: nestedKeys,
            componentBlocks: componentBlocks,
            flatCSS: flatCSS
        )
    }

    /// Returns all collected entries as flat rules for backward compatibility.
    ///
    /// Entries are deduplicated by declaration fingerprint and assigned
    /// sequential class names.
    public func collectedRules() -> [Rule] {
        var seen: [String: Rule] = [:]
        var order: [String] = []
        var nextIndex = 0

        for entry in entries where !entry.declarationKey.isEmpty {
            if seen[entry.declarationKey] == nil {
                seen[entry.declarationKey] = Rule(
                    className: "s-\(nextIndex)",
                    declarations: entry.declarations
                )
                order.append(entry.declarationKey)
                nextIndex += 1
            }
        }

        return order.compactMap { seen[$0] }
    }

    // MARK: - Tree Walking

    private func isLeafNode<N: Node>(_ node: N) -> Bool {
        N.Body.self == Never.self
    }

    private mutating func walk(_ node: some Node) {
        if let modified = node as? any ModifierChainLinkable {
            let (allModifiers, innerNode) = flattenChain(modified)
            let tag = (innerNode as? any CSSWalkable)?.htmlTag
            registerModifiers(allModifiers, htmlTag: tag)
            collect(from: innerNode)
            return
        }

        if let walkable = node as? any CSSWalkable {
            walkable.walkChildren(collector: &self)
            return
        }

        if isLeafNode(node) { return }

        if node is any Component {
            let name = CSSNaming.className(from: String(describing: type(of: node)))
            componentStack.append(name)
            collect(from: node.body)
            componentStack.removeLast()
        } else {
            collect(from: node.body)
        }
    }

    private func flattenChain(_ modified: any ModifierChainLinkable) -> ([any ModifierValue], any Node) {
        var allModifiers = modified.chainModifiers
        var current = modified.chainContent
        while let inner = current as? any ModifierChainLinkable {
            allModifiers.append(contentsOf: inner.chainModifiers)
            current = inner.chainContent
        }
        return (allModifiers, current)
    }

    private mutating func registerModifiers(_ modifiers: [any ModifierValue], htmlTag: String?) {
        var baseModifiers: [any ModifierValue] = []
        var pseudoModifiers: [PseudoClassModifier] = []

        for modifier in modifiers {
            if let pseudo = modifier as? PseudoClassModifier {
                pseudoModifiers.append(pseudo)
            } else {
                baseModifiers.append(modifier)
            }
        }

        var declarations: [CSSDeclaration] = []
        for modifier in baseModifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }

        var pseudoEntries: [PseudoEntry] = []
        for pseudo in pseudoModifiers {
            let decls = pseudo.styles.map { $0.cssDeclaration() }
            if !decls.isEmpty {
                pseudoEntries.append(PseudoEntry(pseudoClass: pseudo.pseudoClass, declarations: decls))
            }
        }

        guard !declarations.isEmpty || !pseudoEntries.isEmpty else { return }

        let declarationKey = declarations.isEmpty ? "" : CSSDeclaration.lookupKey(for: declarations)
        let pseudoKeyParts = pseudoEntries.map {
            "\($0.pseudoClass.rawValue):\(CSSDeclaration.lookupKey(for: $0.declarations))"
        }
        let fullKey = ([declarationKey] + pseudoKeyParts).joined(separator: "|")

        let scope = componentStack.last
        let dedupKey = "\(scope ?? "")|\(htmlTag ?? "")|\(fullKey)"

        guard !seenEntries.contains(dedupKey) else { return }
        seenEntries.insert(dedupKey)

        entries.append(
            Entry(
                declarations: declarations,
                declarationKey: declarationKey,
                pseudoEntries: pseudoEntries,
                componentScope: scope,
                htmlTag: htmlTag
            ))
    }

    // MARK: - Helpers

    private func emitNestedPseudoRules(_ pseudoEntries: [PseudoEntry], indent: String, into css: inout String) {
        for pseudo in pseudoEntries {
            let decls = renderDeclarations(pseudo.declarations, indent: "\(indent)  ")
            css.append("\n\(indent)&:\(pseudo.pseudoClass.rawValue) {\n\(decls)\n\(indent)}")
        }
    }

    private func renderDeclarations(_ declarations: [CSSDeclaration], indent: String) -> String {
        declarations.map { "\(indent)\($0.render());" }.joined(separator: "\n")
    }

    /// Generates a semantic class name from component, tag, and ordinal context.
    ///
    /// When a component scope is present, class names are short (e.g. `.small`)
    /// because they are nested inside the component selector. When no scope
    /// exists, the page name is prefixed instead (e.g. `.home-small`).
    static func semanticClassName(
        component: String?,
        tag: String?,
        pageName: String?,
        ordinal: Int
    ) -> String {
        let tagName = friendlyTagName(tag ?? "div")
        if let component {
            let name = "\(component)-\(tagName)"
            return ordinal > 1 ? "\(name)-\(ordinal)" : name
        }
        let base = pageName ?? "scope"
        let name = "\(base)-\(tagName)"
        return ordinal > 1 ? "\(name)-\(ordinal)" : name
    }

    /// Generic container tags that always receive class names instead of
    /// element-based nested selectors. Using `div { ... }` or `span { ... }`
    /// inside a component scope is fragile because it targets every instance
    /// of that tag, not just the styled one.
    private static let alwaysClassedTags: Set<String> = ["div", "span"]

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
