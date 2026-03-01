import ScoreCSS
import ScoreCore
import ScoreHTML

/// Orchestrates rendering a single ``Page`` into a complete HTML document.
///
/// `PageRenderer` coordinates the CSS collection, class injection, HTML
/// rendering, and document assembly steps that transform a page's node tree
/// into a `<!DOCTYPE html>` string ready to serve as an HTTP response.
///
/// ### Pipeline
///
/// 1. Evaluate the page's `body` to obtain the node tree
/// 2. Run `CSSCollector` to extract scoped CSS rules
/// 3. Build a class injector closure from the collected rules
/// 4. Run `HTMLRenderer` with the injector to produce HTML with class attributes
/// 5. Run `JSEmitter` to produce client-side reactive scripts (if any)
/// 6. Call `DocumentAssembler` to merge everything into a complete document
///
/// ### Example
///
/// ```swift
/// let html = PageRenderer.render(
///     page: homePage,
///     metadata: appMetadata,
///     theme: appTheme
/// )
/// ```
public enum PageRenderer: Sendable {

    /// Renders a page into a complete HTML document.
    ///
    /// - Parameters:
    ///   - page: The page to render.
    ///   - metadata: The application-level metadata, if any.
    ///   - theme: The application theme, if any.
    ///   - environment: The build environment, used to control JS emission.
    ///     Defaults to ``Environment/current``.
    /// - Returns: A complete HTML document string.
    public static func render(
        page: some Page,
        metadata: (any Metadata)?,
        theme: (any Theme)?,
        environment: Environment = .current
    ) -> String {
        let body = page.body

        var collector = CSSCollector()
        collector.collect(from: body)
        let rules = collector.collectedRules()

        let classLookup = buildClassLookup(from: rules)
        let renderer = HTMLRenderer(classInjector: { modifiers in
            classLookup(modifiers)
        })
        let bodyHTML = renderer.render(body)

        let componentCSS = collector.renderStylesheet()
        let themeCSS = theme.map { ThemeCSSEmitter.emit($0) } ?? ""

        let emitResult = JSEmitter.emitWithSourceMap(page: page, environment: environment)
        var scripts: [String] = []
        if !emitResult.script.isEmpty {
            scripts.append("<script src=\"/_score/signal-polyfill.js\"></script>")
            scripts.append("<script src=\"/_score/score-runtime.js\"></script>")
            scripts.append(emitResult.script)
        }

        let patch = page.metadata
        let title = DocumentAssembler.composeTitle(
            page: patch?.title ?? metadata?.title,
            separator: patch?.titleSeparator ?? metadata?.titleSeparator ?? " | ",
            site: patch?.site ?? metadata?.site
        )

        let parts = DocumentAssembler.Parts(
            title: title,
            description: patch?.description ?? metadata?.description,
            keywords: patch?.keywords ?? metadata?.keywords ?? [],
            structuredData: patch?.structuredData ?? metadata?.structuredData ?? [],
            themeCSS: themeCSS,
            componentCSS: componentCSS,
            bodyHTML: bodyHTML,
            scripts: scripts,
            activeTheme: theme?.name
        )

        return DocumentAssembler.assemble(parts)
    }

    /// Result of rendering with dev tools support.
    public struct RenderResult: Sendable {
        /// The complete HTML document string.
        public let html: String
        /// The source map JSON, if emitted in dev mode.
        public let sourceMap: String?
        /// The script ID corresponding to the source map.
        public let scriptID: String?
    }

    /// Renders a page into a complete HTML document with dev tools support.
    ///
    /// In development mode this method:
    /// - Annotates the body HTML with `data-score-component` attributes
    /// - Injects the dev tools panel script
    /// - Injects reactive state metadata for the State tab
    /// - Returns the source map alongside the HTML
    ///
    /// - Parameters:
    ///   - page: The page to render.
    ///   - metadata: The application-level metadata, if any.
    ///   - theme: The application theme, if any.
    ///   - environment: The build environment. Defaults to ``Environment/current``.
    /// - Throws: Rethrows any error encountered during page body evaluation.
    /// - Returns: A ``RenderResult`` containing the HTML and optional source map.
    public static func renderWithDevTools(
        page: some Page,
        metadata: (any Metadata)?,
        theme: (any Theme)?,
        environment: Environment = .current
    ) throws -> RenderResult {
        let body = page.body

        var collector = CSSCollector()
        collector.collect(from: body)
        let rules = collector.collectedRules()

        let classLookup = buildClassLookup(from: rules)
        let renderer = HTMLRenderer(classInjector: { modifiers in
            classLookup(modifiers)
        })
        var bodyHTML = renderer.render(body)

        let componentCSS = collector.renderStylesheet()
        let themeCSS = theme.map { ThemeCSSEmitter.emit($0) } ?? ""

        let emitResult = JSEmitter.emitWithSourceMap(page: page, environment: environment)
        var scripts: [String] = []
        if !emitResult.script.isEmpty {
            scripts.append("<script src=\"/_score/signal-polyfill.js\"></script>")
            scripts.append("<script src=\"/_score/score-runtime.js\"></script>")
            scripts.append(emitResult.script)
        }

        // Dev tools injection.
        let componentName = String(describing: type(of: page))
        bodyHTML = DevToolsInjector.annotateComponent(
            bodyHTML: bodyHTML,
            componentName: componentName,
            sourceFile: "Sources/App/\(componentName).swift",
            sourceLine: 1,
            environment: environment
        )

        let stateNames = JSEmitter.extractStates(from: page).map(\.name)
        let computedNames = JSEmitter.extractComputeds(from: page).map(\.name)
        let metaScript = DevToolsInjector.stateMetadataScript(
            stateNames: stateNames,
            computedNames: computedNames,
            environment: environment
        )
        if !metaScript.isEmpty {
            scripts.append(metaScript)
        }

        let devToolsScript = DevToolsInjector.scriptTag(environment: environment)
        if !devToolsScript.isEmpty {
            scripts.append(devToolsScript)
        }

        let patch = page.metadata
        let title = DocumentAssembler.composeTitle(
            page: patch?.title ?? metadata?.title,
            separator: patch?.titleSeparator ?? metadata?.titleSeparator ?? " | ",
            site: patch?.site ?? metadata?.site
        )

        let parts = DocumentAssembler.Parts(
            title: title,
            description: patch?.description ?? metadata?.description,
            keywords: patch?.keywords ?? metadata?.keywords ?? [],
            structuredData: patch?.structuredData ?? metadata?.structuredData ?? [],
            themeCSS: themeCSS,
            componentCSS: componentCSS,
            bodyHTML: bodyHTML,
            scripts: scripts,
            activeTheme: theme?.name
        )

        return RenderResult(
            html: DocumentAssembler.assemble(parts),
            sourceMap: emitResult.sourceMap,
            scriptID: emitResult.scriptID
        )
    }

    private static func buildClassLookup(
        from rules: [CSSCollector.Rule]
    ) -> @Sendable ([any ModifierValue]) -> String? {
        var mapping: [String: String] = [:]
        for rule in rules {
            mapping[rule.className] = rule.className
        }
        let frozenMapping = mapping

        return { modifiers in
            var declarations: [CSSDeclaration] = []
            for modifier in modifiers {
                declarations.append(contentsOf: CSSEmitter.declarations(for: modifier))
            }
            guard !declarations.isEmpty else { return nil }

            var hasher = Hasher()
            for d in declarations {
                hasher.combine(d.property)
                hasher.combine(d.value)
            }
            let hash = UInt(bitPattern: hasher.finalize())
            let className = "s-\(String(hash, radix: 36))"
            return frozenMapping[className]
        }
    }
}
