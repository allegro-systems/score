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

        let environment = Environment.current

        var renderer = HTMLRenderer(classInjector: { modifiers, scope in
            classMap.className(for: modifiers, scope: scope)
        })
        renderer.componentClassInjector = { node in
            if node is any Component || node is any Page {
                return CSSNaming.className(from: String(describing: type(of: node)))
            }
            return nil
        }
        renderer.isDevMode = environment == .development
        let bodyHTML = renderer.render(page.body)

        // Emit client-side JavaScript for reactive bindings
        let jsResult = JSEmitter.emitPageScript(page: page)

        // Use external script links when provided, otherwise inline
        var inlineScripts: [String]?
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

        // Inject dev tools metadata and script tag in development mode
        var preScripts: [String] = []
        if environment == .development {
            let meta = DevToolsInjector.metadataScript(
                pageStates: jsResult.pageStates,
                pageComputeds: jsResult.pageComputeds,
                pageActions: jsResult.pageActions,
                componentScopes: jsResult.componentScopes,
                environment: environment
            )
            if !meta.isEmpty {
                preScripts.append(meta)
            }
            let devTag = DevToolsInjector.scriptTag(environment: environment)
            if inlineScripts != nil {
                inlineScripts?.append(devTag)
            } else {
                inlineScripts = [devTag]
            }
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
            scriptLinks: resolvedScriptLinks,
            preScripts: preScripts
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

    /// Renders an error page body into a complete HTML document.
    ///
    /// Uses application-level metadata and theme to produce a styled error
    /// page with inline CSS. Unlike ``render(page:metadata:theme:cssLinks:scriptLinks:)``,
    /// this method inlines all styles since error pages are standalone.
    ///
    /// - Parameters:
    ///   - body: The node tree to render (typically from ``Application/errorBody(for:)``).
    ///   - metadata: Application-level metadata for title and description.
    ///   - theme: The active theme.
    /// - Returns: A complete HTML document string.
    public static func renderErrorBody(
        _ body: some Node,
        metadata: (any Metadata)?,
        theme: (any Theme)?
    ) -> String {
        let title = metadata?.title ?? metadata?.site
        let site = metadata?.site

        var collector = CSSCollector()
        collector.pageName = "error"
        collector.collect(from: body)
        let stylesheetResult = collector.renderStylesheet()

        let classMap = ClassMap(
            classLookup: stylesheetResult.classLookup,
            nestedKeys: stylesheetResult.nestedKeys
        )

        var renderer = HTMLRenderer(classInjector: { modifiers, scope in
            classMap.className(for: modifiers, scope: scope)
        })
        renderer.componentClassInjector = { node in
            if node is any Component {
                return CSSNaming.className(from: String(describing: type(of: node)))
            }
            return nil
        }
        let bodyHTML = renderer.render(body)

        let themeCSS = theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        var inlineCSS = themeCSS
        if !stylesheetResult.css.isEmpty {
            inlineCSS.append("\n")
            inlineCSS.append(stylesheetResult.css)
        }

        var inlineStyles: String?
        if !inlineCSS.isEmpty {
            inlineStyles = "<style>\(inlineCSS)</style>"
        }

        let parts = DocumentAssembler.Parts(
            title: title,
            bodyHTML: bodyHTML,
            activeTheme: theme?.name,
            ogSiteName: site,
            themeNames: theme.map { Array($0.named.keys) } ?? []
        )

        var html = DocumentAssembler.assemble(parts)
        if let inlineStyles {
            html = html.replacingOccurrences(
                of: "</head>",
                with: "\(inlineStyles)\n</head>"
            )
        }

        return html
    }

}

/// Maps modifier arrays to CSS class names, returning `nil` for entries
/// handled by CSS nesting (no wrapper div needed).
private struct ClassMap: Sendable {
    let classLookup: [String: String]
    let nestedKeys: Set<String>

    func className(for modifiers: [any ModifierValue], scope: String?) -> String? {
        var declarations: [CSSDeclaration] = []
        for modifier in modifiers {
            declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
        }
        guard !declarations.isEmpty else { return nil }
        let key = CSSDeclaration.lookupKey(for: declarations)
        let scopedKey = "\(scope ?? "")|\(key)"
        if nestedKeys.contains(scopedKey) { return nil }
        return classLookup[scopedKey]
    }
}
