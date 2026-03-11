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
    /// Per-component CSS blocks keyed by scope name, for chunking shared
    /// styles into a separate stylesheet during static builds.
    public let componentBlocks: [String: String]
    /// CSS for entries without a component scope.
    public let flatCSS: String
    /// The emitted client-side JavaScript, if the page has reactive bindings.
    public let script: String
    /// The page-specific JavaScript without the shared runtime.
    public let pageJS: String
    /// JavaScript for page-level declarations (outside any `Element`).
    public let pageLevelJS: String
    /// Per-`Element` JavaScript blocks for scope-level deduplication.
    public let jsScopeBlocks: [String]
    /// Whether this page requires the Score signals runtime.
    public let needsRuntime: Bool
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
    ///   - scriptLinks: External JavaScript file paths to link before `</body>`.
    ///     When provided, scripts are loaded externally instead of inlined.
    /// - Returns: A `RenderResult` containing the HTML and extracted component CSS.
    public static func render(
        page: some Page,
        metadata appMeta: (any Metadata)?,
        theme: (any Theme)?,
        cssLinks: [String] = [],
        scriptLinks: [String] = []
    ) -> RenderResult {
        let pageMeta = page.metadata

        // Compose title
        let pageTitle = pageMeta?.title ?? appMeta?.title
        let site = pageMeta?.site ?? appMeta?.site
        let separator = pageMeta?.titleSeparator ?? appMeta?.titleSeparator ?? " — "
        let title = DocumentAssembler.composeTitle(page: pageTitle, separator: separator, site: site)

        // Description, keywords, and canonical URL
        let description = pageMeta?.description ?? appMeta?.description
        let keywords = pageMeta?.keywords ?? appMeta?.keywords
        let structuredData = pageMeta?.structuredData ?? appMeta?.structuredData
        let baseURL = pageMeta?.baseURL ?? appMeta?.baseURL
        let canonicalURL = baseURL.map { $0 + page.path }
        let ogSiteName = pageMeta?.site ?? appMeta?.site

        // Collect CSS from node tree with component scope tracking
        var collector = CSSCollector()
        collector.pageName = CSSNaming.className(from: String(describing: type(of: page)))
        collector.collect(from: page.body)
        let stylesheetResult = collector.renderStylesheet()

        // Build class map from stylesheet analysis
        let classMap = ClassMap(
            classLookup: stylesheetResult.classLookup,
            nestedKeys: stylesheetResult.nestedKeys
        )

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

        // Emit client-side JavaScript for reactive bindings
        let jsResult = JSEmitter.emitPageScript(page: page)

        // Use external script links when provided, otherwise inline
        let inlineScripts: [String]?
        let resolvedScriptLinks: [String]
        if !scriptLinks.isEmpty && !jsResult.pageJS.isEmpty {
            inlineScripts = nil
            resolvedScriptLinks = scriptLinks
        } else if !jsResult.pageJS.isEmpty {
            var inlineJS = ""
            if jsResult.needsRuntime {
                inlineJS.append(JSEmitter.clientRuntime)
            }
            inlineJS.append(jsResult.pageJS)
            inlineScripts = ["<script>\n\(inlineJS)</script>"]
            resolvedScriptLinks = []
        } else {
            inlineScripts = nil
            resolvedScriptLinks = []
        }

        let parts = DocumentAssembler.Parts(
            title: title,
            description: description,
            keywords: keywords,
            bodyHTML: bodyHTML,
            cssLinks: cssLinks,
            structuredData: structuredData,
            scripts: inlineScripts,
            activeTheme: theme?.name,
            canonicalURL: canonicalURL,
            ogSiteName: ogSiteName,
            themeNames: theme.map { Array($0.named.keys) } ?? [],
            scriptLinks: resolvedScriptLinks
        )

        return RenderResult(
            html: DocumentAssembler.assemble(parts),
            componentCSS: stylesheetResult.css,
            componentBlocks: stylesheetResult.componentBlocks,
            flatCSS: stylesheetResult.flatCSS,
            script: jsResult.pageJS.isEmpty ? "" : "<script>\n\(jsResult.needsRuntime ? JSEmitter.clientRuntime : "")\(jsResult.pageJS)</script>",
            pageJS: jsResult.pageJS,
            pageLevelJS: jsResult.pageLevelJS,
            jsScopeBlocks: jsResult.scopeBlocks,
            needsRuntime: jsResult.needsRuntime
        )
    }

}

/// Maps modifier arrays to CSS class names, returning `nil` for entries
/// handled by CSS nesting (no wrapper div needed).
private struct ClassMap: Sendable {
    let classLookup: [String: String]
    let nestedKeys: Set<String>

    func className(for modifiers: [any ModifierValue]) -> String? {
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }
        guard !declarations.isEmpty else { return nil }
        let key = CSSDeclaration.lookupKey(for: declarations)
        if nestedKeys.contains(key) { return nil }
        return classLookup[key]
    }
}
