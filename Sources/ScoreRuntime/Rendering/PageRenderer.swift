import ScoreCSS
import ScoreCore
import ScoreHTML

/// The result of rendering a page, containing both the HTML document
/// and the extracted component CSS for external file serving.
public struct RenderResult: Sendable {
    /// The complete HTML document string.
    public let html: String
    /// The extracted CSS outputs from the page's node tree.
    public let css: CSSOutput
    /// The emitted client-side JavaScript outputs.
    public let js: JSOutput

    /// CSS outputs extracted during page rendering.
    public struct CSSOutput: Sendable {
        /// The component-scoped CSS extracted from the page's node tree.
        public let full: String
        /// Per-component CSS blocks keyed by scope name, for chunking shared
        /// styles into a separate stylesheet during static builds.
        public let componentBlocks: [String: String]
        /// Component scope names in DOM order, for preserving cascade ordering.
        public let scopeOrder: [String]
        /// CSS for entries without a component scope.
        public let flat: String
    }

    /// JavaScript outputs emitted during page rendering.
    public struct JSOutput: Sendable {
        /// The emitted client-side JavaScript, if the page has reactive bindings.
        public let inline: String
        /// The page-specific JavaScript without the shared runtime.
        public let perPage: String
        /// JavaScript for page-level declarations (outside any `Element`).
        public let pageLevel: String
        /// Per-`Element` JavaScript blocks for scope-level deduplication.
        public let scopeBlocks: [String]
        /// Whether this page requires the Score signals runtime.
        public let needsRuntime: Bool
        /// Whether this page requires the local-first IndexedDB runtime.
        public let needsLocalFirstRuntime: Bool
    }
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
    ///   - locale: The locale for this rendering pass. Sets the `lang`
    ///     attribute on `<html>` and activates the ``LocalizationContext``.
    ///   - localization: The i18n configuration. When non-nil, a
    ///     ``LocalizationContext`` is installed so ``Localized`` nodes and
    ///     ``t(_:default:)`` calls resolve translations.
    ///   - cssLinks: External CSS file paths to link in `<head>`.
    ///   - headLinks: Extra `<link>` tags for `<head>` (preconnects, external stylesheets).
    ///   - scriptLinks: External JavaScript file paths to link before `</body>`.
    ///     When provided, scripts are loaded externally instead of inlined.
    /// - Returns: A `RenderResult` containing the HTML and extracted component CSS.
    public static func render(
        page: some Page,
        metadata appMeta: (any Metadata)?,
        theme: (any Theme)?,
        locale: SiteLocale? = nil,
        localization: Localization? = nil,
        cssLinks: [String] = [],
        headLinks: [String] = [],
        scriptLinks: [String] = []
    ) -> RenderResult {
        let environment = Environment.current

        // Install localization context for the entire rendering pass.
        // CSS collection, metadata, and HTML rendering all need it so
        // components that depend on locale data (e.g. LanguageDropdown)
        // produce consistent output.
        let context: LocalizationContext? =
            if let localization, let locale {
                LocalizationContext(locale: locale, localization: localization)
            } else {
                nil
            }

        return LocalizationContext.$current.withValue(context) {
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
            // Resolve metadata inside localization context so `t()` calls
            // in metadata properties return locale-specific translations.
            let pageMeta = page.metadata

            let pageTitle = pageMeta?.title ?? appMeta?.title
            let site = pageMeta?.site ?? appMeta?.site
            let separator = pageMeta?.titleSeparator ?? appMeta?.titleSeparator ?? " — "
            let title = DocumentAssembler.composeTitle(page: pageTitle, separator: separator, site: site)

            let description = pageMeta?.description ?? appMeta?.description
            let keywords = pageMeta?.keywords ?? appMeta?.keywords
            let structuredData = pageMeta?.structuredData ?? appMeta?.structuredData
            let baseURL = pageMeta?.baseURL ?? appMeta?.baseURL
            let canonicalURL = baseURL.map { $0 + page.path }
            let ogSiteName = pageMeta?.site ?? appMeta?.site

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
            var resolvedScriptLinks: [String]
            if !scriptLinks.isEmpty && !jsResult.pageJS.isEmpty {
                inlineScripts = nil
                resolvedScriptLinks = scriptLinks
            } else if !jsResult.pageJS.isEmpty {
                var inlineJS = ""
                if jsResult.needsRuntime {
                    inlineJS.append(JSEmitter.clientRuntime)
                }
                if jsResult.needsLocalFirstRuntime {
                    inlineJS.append(JSEmitter.localFirstRuntime)
                }
                inlineJS.append(jsResult.pageJS)
                inlineScripts = ["<script>\n\(inlineJS)</script>"]
                resolvedScriptLinks = []
            } else {
                inlineScripts = nil
                resolvedScriptLinks = []
            }

            // Inject scroll observer when page uses animateOnScroll
            if bodyHTML.contains("data-scroll-animate") {
                if !scriptLinks.isEmpty {
                    // Static build: reference the external file
                    resolvedScriptLinks.append("/scripts/_score-scroll.js")
                } else if inlineScripts != nil {
                    inlineScripts?.append("<script>\(JSEmitter.scrollObserverRuntime)</script>")
                } else {
                    inlineScripts = ["<script>\(JSEmitter.scrollObserverRuntime)</script>"]
                }
            }

            // Inject code-copy handler when page has code blocks
            if bodyHTML.contains("data-code-copy") {
                if !scriptLinks.isEmpty {
                    resolvedScriptLinks.append("/scripts/_score-code-copy.js")
                } else if inlineScripts != nil {
                    inlineScripts?.append("<script>\(JSEmitter.codeCopyRuntime)</script>")
                } else {
                    inlineScripts = ["<script>\(JSEmitter.codeCopyRuntime)</script>"]
                }
            }

            // Inject tab-group initializer when page has tab groups
            if bodyHTML.contains("data-tab-group") {
                if !scriptLinks.isEmpty {
                    resolvedScriptLinks.append("/scripts/_score-tabs.js")
                } else if inlineScripts != nil {
                    inlineScripts?.append("<script>\(JSEmitter.tabGroupRuntime)</script>")
                } else {
                    inlineScripts = ["<script>\(JSEmitter.tabGroupRuntime)</script>"]
                }
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
                headLinks: headLinks,
                themeNames: theme.map { Array($0.named.keys) } ?? [],
                scriptLinks: resolvedScriptLinks,
                preScripts: preScripts,
                viewTransitions: theme?.viewTransitions ?? false,
                locale: locale?.identifier ?? "en"
            )

            return RenderResult(
                html: DocumentAssembler.assemble(parts),
                css: RenderResult.CSSOutput(
                    full: stylesheetResult.css,
                    componentBlocks: stylesheetResult.componentBlocks,
                    scopeOrder: stylesheetResult.scopeOrder,
                    flat: stylesheetResult.flatCSS
                ),
                js: RenderResult.JSOutput(
                    inline: jsResult.pageJS.isEmpty ? "" : "<script>\n\(jsResult.needsRuntime ? JSEmitter.clientRuntime : "")\(jsResult.needsLocalFirstRuntime ? JSEmitter.localFirstRuntime : "")\(jsResult.pageJS)</script>",
                    perPage: jsResult.pageJS,
                    pageLevel: jsResult.pageLevelJS,
                    scopeBlocks: jsResult.scopeBlocks,
                    needsRuntime: jsResult.needsRuntime,
                    needsLocalFirstRuntime: jsResult.needsLocalFirstRuntime
                )
            )
        }  // LocalizationContext.$current.withValue
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
            themeNames: theme.map { Array($0.named.keys) } ?? [],
            viewTransitions: theme?.viewTransitions ?? false
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
        declarations = CSSCollector.mergeTransitions(declarations)
        let key = CSSDeclaration.lookupKey(for: declarations)
        let scopedKey = "\(scope ?? "")|\(key)"
        if nestedKeys.contains(scopedKey) { return nil }
        return classLookup[scopedKey]
    }
}
