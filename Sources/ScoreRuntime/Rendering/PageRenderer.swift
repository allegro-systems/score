import ScoreCore
import ScoreCSS
import ScoreHTML

/// Renders a `Page` to a complete HTML document string.
public struct PageRenderer: Sendable {

    private init() {}

    /// Renders a page with optional application metadata and theme.
    public static func render(
        page: some Page,
        metadata appMeta: (any Metadata)?,
        theme: (any Theme)?
    ) -> String {
        let pageMeta = page.metadata

        // Compose title
        let pageTitle = pageMeta?.title ?? appMeta?.title
        let site = pageMeta?.site ?? appMeta?.site
        let separator = pageMeta?.titleSeparator ?? appMeta?.titleSeparator ?? " — "
        let title = DocumentAssembler.composeTitle(page: pageTitle, separator: separator, site: site)

        // Description and keywords
        let description = pageMeta?.description ?? appMeta?.description
        let keywords = pageMeta?.keywords ?? appMeta?.keywords
        let structuredData = pageMeta?.structuredData ?? appMeta?.structuredData

        // Render body HTML with class injection for scoped CSS
        var collector = CSSCollector()
        let classMap = buildClassMap(page: page, collector: &collector)

        let renderer = HTMLRenderer(classInjector: { modifiers in
            classMap.className(for: modifiers)
        })
        let bodyHTML = renderer.render(page.body)

        // Component CSS
        let componentCSS = collector.renderStylesheet()

        // Theme CSS
        let themeCSS: String? = theme.map { ThemeCSSEmitter.emit($0) }

        let parts = DocumentAssembler.Parts(
            title: title,
            description: description,
            keywords: keywords,
            bodyHTML: bodyHTML,
            themeCSS: themeCSS,
            componentCSS: componentCSS.isEmpty ? nil : componentCSS,
            structuredData: structuredData,
            activeTheme: theme?.name
        )

        return DocumentAssembler.assemble(parts)
    }

    private static func buildClassMap(
        page: some Page,
        collector: inout CSSCollector
    ) -> ClassMap {
        collector.collect(from: page.body)
        let rules = collector.collectedRules()

        // Build a lookup from declaration content hash to class name
        var map: [String: String] = [:]
        for rule in rules {
            let key = rule.declarations.map { "\($0.property):\($0.value)" }.joined(separator: ";")
            map[key] = rule.className
        }

        return ClassMap(declarationKeyToClass: map)
    }
}

/// Maps modifier arrays to CSS class names via declaration content matching.
private struct ClassMap: Sendable {
    let declarationKeyToClass: [String: String]

    func className(for modifiers: [any ModifierValue]) -> String? {
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }
        guard !declarations.isEmpty else { return nil }
        let key = declarations.map { "\($0.property):\($0.value)" }.joined(separator: ";")
        return declarationKeyToClass[key]
    }
}
