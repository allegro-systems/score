import ScoreCSS
import ScoreCore
import ScoreHTML

/// The result of rendering a page, containing both the HTML document
/// and the extracted component CSS for external file serving.
public struct RenderResult: Sendable {
    /// The complete HTML document string.
    public let html: String
    /// The component-scoped CSS extracted from the page's node tree.
    public let componentCSS: String
}

/// Renders a `Page` to a complete HTML document string.
public struct PageRenderer: Sendable {

    private init() {}

    /// Renders a page with optional application metadata, theme, and CSS links.
    ///
    /// - Parameters:
    ///   - page: The page to render.
    ///   - appMeta: Application-level metadata.
    ///   - theme: The active theme.
    ///   - cssLinks: External CSS file paths to link in `<head>`.
    /// - Returns: A `RenderResult` containing the HTML and extracted component CSS.
    public static func render(
        page: some Page,
        metadata appMeta: (any Metadata)?,
        theme: (any Theme)?,
        cssLinks: [String] = []
    ) -> RenderResult {
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

        var renderer = HTMLRenderer(classInjector: { modifiers in
            classMap.className(for: modifiers)
        })
        renderer.componentClassInjector = { node in
            if node is any Component || node is any Page {
                return CSSNaming.className(from: String(describing: type(of: node)))
            }
            return nil
        }
        let bodyHTML = renderer.render(page.body)

        // Component CSS
        let componentCSS = collector.renderStylesheet()

        let parts = DocumentAssembler.Parts(
            title: title,
            description: description,
            keywords: keywords,
            bodyHTML: bodyHTML,
            cssLinks: cssLinks,
            structuredData: structuredData,
            activeTheme: theme?.name
        )

        return RenderResult(
            html: DocumentAssembler.assemble(parts),
            componentCSS: componentCSS
        )
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
