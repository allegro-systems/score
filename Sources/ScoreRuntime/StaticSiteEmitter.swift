import Foundation
import ScoreCSS
import ScoreCore
import ScoreHTML

/// Renders all pages of an application to static HTML, CSS, and JS files on disk.
///
/// `StaticSiteEmitter` walks every page in an application, runs the full render
/// pipeline, and writes the output to the application's ``Application/outputDirectory``.
///
/// ### Output Structure
///
/// ```
/// {outputDirectory}/static/
///   index.html
///   about/index.html
///   as-global.css
///   as-group-0.css
///   signal-polyfill.js     (only if reactive pages exist)
///   score-runtime.js       (only if reactive pages exist)
///   as-interactivity.js    (only if reactive pages exist)
/// ```
///
/// ### Example
///
/// ```swift
/// let app = MyApp()
/// try StaticSiteEmitter.emit(application: app)
/// ```
public struct StaticSiteEmitter: Sendable {

    private init() {}

    /// Renders all pages and writes static output to disk.
    ///
    /// - Parameters:
    ///   - application: The application whose pages should be rendered.
    ///   - environment: The build environment. Defaults to ``Environment/production``.
    /// - Throws: An error if directories cannot be created or files cannot be written.
    public static func emit(application: some Application, environment: Environment = .production) throws {
        let outputRoot = application.outputDirectory + "/static"
        let fm = FileManager.default

        try fm.createDirectory(atPath: outputRoot, withIntermediateDirectories: true)

        let theme = application.theme
        let metadata = application.metadata

        let themeCSS = theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        let uiCSS = ThemeCSSEmitter.emitComponentCSS()
        let globalCSS = themeCSS.isEmpty ? uiCSS : themeCSS + "\n" + uiCSS

        try globalCSS.write(toFile: outputRoot + "/as-global.css", atomically: true, encoding: .utf8)

        var allScopedCSS = ""
        var allJS = ""
        var hasReactivity = false

        for page in application.pages {
            let (html, scopedCSS, js) = renderPage(page, metadata: metadata, theme: theme, environment: environment)

            if !scopedCSS.isEmpty {
                allScopedCSS.append(scopedCSS)
            }

            if !js.isEmpty {
                hasReactivity = true
                allJS.append("// \(type(of: page).path)\n")
                allJS.append(js)
                allJS.append("\n")
            }

            let pagePath = type(of: page).path
            let filePath: String
            if pagePath == "/" {
                filePath = outputRoot + "/index.html"
            } else {
                let dir = outputRoot + pagePath
                try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
                filePath = dir + "/index.html"
            }

            try html.write(toFile: filePath, atomically: true, encoding: .utf8)
        }

        if !allScopedCSS.isEmpty {
            try allScopedCSS.write(toFile: outputRoot + "/as-group-0.css", atomically: true, encoding: .utf8)
        }

        if hasReactivity {
            try allJS.write(toFile: outputRoot + "/as-interactivity.js", atomically: true, encoding: .utf8)
            try copyBundleResource("signal-polyfill", to: outputRoot + "/signal-polyfill.js")
            try copyBundleResource("score-runtime", to: outputRoot + "/score-runtime.js")
        }
    }

    private static func renderPage(
        _ page: some Page,
        metadata: Metadata?,
        theme: (any Theme)?,
        environment: Environment
    ) -> (html: String, scopedCSS: String, js: String) {
        let body = page.body

        var collector = CSSCollector()
        collector.collect(from: body)
        let rules = collector.collectedRules()

        let classLookup = PageRenderer.buildClassLookup(from: rules)
        let scopeInjector = JSEmitter.buildScopeInjector()
        let renderer = HTMLRenderer(
            classInjector: { modifiers in classLookup(modifiers) },
            scopeInjector: scopeInjector
        )
        let bodyHTML = renderer.render(body)

        let scopedCSS = collector.renderStylesheet()

        let emitResult = JSEmitter.emitWithSourceMap(page: page, environment: environment)

        var rawJS = ""
        if !emitResult.script.isEmpty {
            rawJS = emitResult.script
                .replacingOccurrences(of: "<script>\n", with: "")
                .replacingOccurrences(of: "</script>", with: "")
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
            themeCSS: "",
            componentCSS: scopedCSS,
            bodyHTML: bodyHTML,
            scripts: emitResult.script.isEmpty ? [] : [emitResult.script],
            activeTheme: theme?.name,
            externalAssets: true
        )

        return (DocumentAssembler.assemble(parts), scopedCSS, rawJS)
    }

    private static func copyBundleResource(_ name: String, to destination: String) throws {
        guard let url = Bundle.module.url(forResource: name, withExtension: "js"),
            let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return
        }
        try contents.write(toFile: destination, atomically: true, encoding: .utf8)
    }
}
