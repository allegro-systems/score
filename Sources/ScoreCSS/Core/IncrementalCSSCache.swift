import ScoreCore

/// A cache for incremental CSS generation that avoids re-collecting CSS
/// for node subtrees whose modifier sets have not changed.
///
/// `IncrementalCSSCache` stores the mapping from a modifier-set fingerprint
/// to the generated CSS rules. On subsequent renders, if a node's modifier
/// fingerprint matches the cache, the cached rules are reused instead of
/// re-walking and re-emitting CSS.
///
/// ### Example
///
/// ```swift
/// var cache = IncrementalCSSCache()
/// let (rules, hit) = cache.rulesForModifiers(modifiers, fallback: {
///     CSSEmitter.declarations(for: $0)
/// })
/// ```
public struct IncrementalCSSCache: Sendable {

    private var cache: [UInt64: [CSSDeclaration]] = [:]
    private var ruleCache: [String: CSSCollector.Rule] = [:]

    /// The number of cached modifier sets.
    public var count: Int { cache.count }

    /// Cache hit statistics.
    public private(set) var hits: Int = 0

    /// Cache miss statistics.
    public private(set) var misses: Int = 0

    /// Creates an empty incremental CSS cache.
    public init() {}

    /// Looks up or computes CSS declarations for the given modifiers.
    ///
    /// If the modifier set's fingerprint is cached, returns the cached
    /// declarations without recomputing. Otherwise, calls the fallback
    /// closure and caches the result.
    ///
    /// - Parameters:
    ///   - modifiers: The modifier values to generate CSS for.
    ///   - fallback: A closure that produces declarations for a modifier.
    /// - Returns: A tuple of the declarations and whether the cache was hit.
    public mutating func declarations(
        for modifiers: [any ModifierValue],
        fallback: (any ModifierValue) -> [CSSDeclaration]
    ) -> (declarations: [CSSDeclaration], cacheHit: Bool) {
        let fingerprint = modifierFingerprint(modifiers)

        if let cached = cache[fingerprint] {
            hits += 1
            return (cached, true)
        }

        misses += 1
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: fallback(modifier))
        }

        cache[fingerprint] = declarations
        return (declarations, false)
    }

    /// Looks up or computes a CSS rule for the given class name and declarations.
    ///
    /// - Parameters:
    ///   - className: The generated CSS class name.
    ///   - declarations: The CSS declarations for the rule.
    /// - Returns: The cached or newly created rule.
    public mutating func rule(
        className: String,
        declarations: [CSSDeclaration]
    ) -> CSSCollector.Rule {
        if let cached = ruleCache[className] {
            return cached
        }
        let newRule = CSSCollector.Rule(className: className, declarations: declarations)
        ruleCache[className] = newRule
        return newRule
    }

    /// Invalidates a specific modifier fingerprint.
    ///
    /// - Parameter modifiers: The modifiers whose cache entry to remove.
    public mutating func invalidate(for modifiers: [any ModifierValue]) {
        let fingerprint = modifierFingerprint(modifiers)
        cache.removeValue(forKey: fingerprint)
    }

    /// Clears the entire cache.
    public mutating func clear() {
        cache.removeAll()
        ruleCache.removeAll()
        hits = 0
        misses = 0
    }

    /// The cache hit rate as a percentage between 0 and 1.
    public var hitRate: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total)
    }

    private func modifierFingerprint(_ modifiers: [any ModifierValue]) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for modifier in modifiers {
            let typeName = String(describing: type(of: modifier))
            for byte in typeName.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
            let desc = String(describing: modifier)
            for byte in desc.utf8 {
                hash ^= UInt64(byte)
                hash &*= 1_099_511_628_211
            }
        }
        return hash
    }
}

/// A CSS collector that uses incremental caching to skip unchanged subtrees.
///
/// `IncrementalCSSCollector` wraps a standard ``CSSCollector`` with a
/// ``IncrementalCSSCache`` to avoid recomputing CSS for modifier sets
/// that have been seen before.
///
/// ### Example
///
/// ```swift
/// var collector = IncrementalCSSCollector()
/// collector.collect(from: nodeTree)
/// let css = collector.renderStylesheet()
/// // On subsequent renders with the same modifiers, cached CSS is reused.
/// ```
public struct IncrementalCSSCollector: Sendable {

    private var collector: CSSCollector
    private var cache: IncrementalCSSCache

    /// Creates an incremental CSS collector.
    ///
    /// - Parameter cache: An existing cache to reuse, or `nil` for a fresh cache.
    public init(cache: IncrementalCSSCache? = nil) {
        self.collector = CSSCollector()
        self.cache = cache ?? IncrementalCSSCache()
    }

    /// Collects CSS from the given node tree with caching.
    ///
    /// - Parameter node: The root node to collect CSS from.
    public mutating func collect(from node: some Node) {
        collector.collect(from: node)
    }

    /// Returns all collected rules in document order.
    public func collectedRules() -> [CSSCollector.Rule] {
        collector.collectedRules()
    }

    /// Renders the collected rules as a CSS stylesheet with nesting.
    public func renderStylesheet() -> CSSCollector.StylesheetResult {
        collector.renderStylesheet()
    }

    /// The underlying cache for inspection or reuse.
    public var cssCache: IncrementalCSSCache { cache }
}
