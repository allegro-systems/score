import Foundation
import ScoreAssets
import ScoreCore

/// Errors raised by the static site emitter.
public enum StaticSiteEmitterError: Error, Sendable, CustomStringConvertible {

    /// A required bundled resource was not found.
    case missingResource(String)

    public var description: String {
        switch self {
        case .missingResource(let name):
            return "Missing bundled resource: \(name)"
        }
    }
}

/// A rendered page entry used during static site emission.
private struct RenderedPageEntry {
    let pagePath: String
    let cssName: String
    let result: RenderResult
}

/// A CSS chunk file shared by a subset of pages.
private struct ChunkFile {
    let name: String
    let css: String
    let pages: Set<String>
}

/// Emits a static site from an `Application` to disk.
public struct StaticSiteEmitter: Sendable {

    private init() {}

    /// Derives a CSS/JS file name from a page path.
    ///
    /// - `/` → `"home"`
    /// - `/about` → `"about"`
    /// - `/docs/score` → `"docs-score"`
    public static func fileName(for pagePath: String) -> String {
        if pagePath == "/" { return "home" }
        let trimmed = pagePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.replacingOccurrences(of: "/", with: "-")
    }

    /// Renders all pages and writes them, along with external CSS and JS files,
    /// to the application's output directory.
    ///
    /// Component CSS is chunked by usage pattern: components used on all pages
    /// go into `shared.css`, components shared by a subset of pages go into
    /// named chunk files (e.g. `docs-score.css`), and page-unique styles stay
    /// in per-page files.
    ///
    /// JavaScript is chunked similarly: Element scope blocks used on all
    /// reactive pages go into `shared.js`, blocks shared by a subset go into
    /// named chunks, and page-unique blocks plus page-level declarations stay
    /// in per-page files. The Score signals runtime is written to `score.js`.
    ///
    /// The output directory is wiped clean before each emission so stale
    /// files from previous builds never linger.
    public static func emit(application: some Application) throws {
        let outputDir = application.outputDirectory
        let fm = FileManager.default
        let environment = Environment.current
        let minify = environment == .production

        if fm.fileExists(atPath: outputDir) {
            try fm.removeItem(atPath: outputDir)
        }
        try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let stylesDir = "\(outputDir)/styles"
        let scriptsDir = "\(outputDir)/scripts"
        try fm.createDirectory(atPath: stylesDir, withIntermediateDirectories: true)

        // Process resources directory (fonts, images, etc.)
        let assetManifest: AssetManifest?
        let resourcesDir = application.resourcesDirectory
        if fm.fileExists(atPath: resourcesDir) {
            let pipeline = AssetPipeline(
                sourceDirectory: resourcesDir,
                outputDirectory: "\(outputDir)/assets"
            )
            assetManifest = try pipeline.process()
        } else {
            assetManifest = nil
        }

        let plugins = application.plugins

        let themeHeadLinks =
            application.theme.map {
                ThemeCSSEmitter.headLinks($0, plugins: plugins)
            } ?? []

        if environment == .development {
            let staticDir = "\(outputDir)/static"
            try fm.createDirectory(atPath: staticDir, withIntermediateDirectories: true)
            try DevToolsInjector.clientScript.write(
                toFile: "\(staticDir)/score-devtools.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Determine locale variants to render.
        let localization = application.localization
        let localesToRender = Self.resolvedLocales(localization)

        // Render all pages with placeholder CSS and JS links.
        // The actual links are rewritten after chunk computation.
        // When localization is configured, pages are rendered once per locale.
        var rendered: [RenderedPageEntry] = []
        var anyPageNeedsRuntime = false
        var anyPageNeedsLocalFirst = false

        let theme = application.theme
        let metadata = application.metadata

        // Pre-compute script links per page (locale-independent).
        var pageScriptLinks: [String: [String]] = [:]
        for page in application.pages {
            let cssName = Self.fileName(for: page.path)
            var scriptLinks: [String] = []
            let jsResult = JSEmitter.emitPageScript(page: page)
            if !jsResult.pageJS.isEmpty {
                if jsResult.needsRuntime {
                    scriptLinks.append("/scripts/_score.js")
                    anyPageNeedsRuntime = true
                }
                if jsResult.needsLocalFirstRuntime {
                    scriptLinks.append("/scripts/_score-local.js")
                    anyPageNeedsLocalFirst = true
                }
                scriptLinks.append("/scripts/\(cssName).js")
            }
            scriptLinks.append(contentsOf: plugins.flatMap(\.scriptLinks))
            pageScriptLinks[cssName] = scriptLinks
        }

        for locale in localesToRender {
            let isDefault = localization == nil || locale == localization?.defaultLocale
            let pathPrefix = isDefault ? "" : "/\(locale.identifier)"

            for page in application.pages {
                let pagePath = pathPrefix + page.path
                let cssName = Self.fileName(for: page.path)
                let scriptLinks = pageScriptLinks[cssName] ?? []

                let result = PageRenderer.render(
                    page: page,
                    metadata: metadata,
                    theme: theme,
                    locale: locale,
                    localization: localization,
                    cssLinks: ["/styles/global.css", "/styles/\(cssName).css"],
                    headLinks: themeHeadLinks,
                    scriptLinks: scriptLinks
                )

                rendered.append(RenderedPageEntry(pagePath: pagePath, cssName: cssName, result: result))
            }
        }

        // Compute usage flags from rendered HTML for global CSS tree-shaking
        var usage = ThemeCSSEmitter.UsageFlags()
        for entry in rendered {
            let html = entry.result.html
            if html.contains("data-spinner") { usage.spinners = true }
            if html.contains("data-tab-group") { usage.tabGroups = true }
            if html.contains("data-code-block") { usage.codeBlocks = true }
            if html.contains("<table") { usage.tables = true }
            if html.contains("<blockquote") { usage.blockquotes = true }
        }

        // Write global CSS into styles/
        let globalCSS =
            application.theme.map {
                ThemeCSSEmitter.emit($0, plugins: plugins, assetManifest: assetManifest, usage: usage)
            } ?? ""
        try transform(globalCSS, minify: minify, using: Minifier.minifyCSS).write(
            toFile: "\(stylesDir)/global.css",
            atomically: true,
            encoding: .utf8
        )

        // Write shared Score runtime into scripts/
        try fm.createDirectory(atPath: scriptsDir, withIntermediateDirectories: true)
        if anyPageNeedsRuntime {
            try JSEmitter.clientRuntime.write(
                toFile: "\(scriptsDir)/_score.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Write local-first sync runtime
        if anyPageNeedsLocalFirst {
            try JSEmitter.localFirstRuntime.write(
                toFile: "\(scriptsDir)/_score-local.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Write scroll observer runtime if any page uses animateOnScroll
        let anyPageUsesScrollAnimate = rendered.contains { $0.result.html.contains("data-scroll-animate") }
        if anyPageUsesScrollAnimate {
            try JSEmitter.scrollObserverRuntime.write(
                toFile: "\(scriptsDir)/_score-scroll.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Write code-copy runtime if any page uses code blocks
        if rendered.contains(where: { $0.result.html.contains("data-code-copy") }) {
            try JSEmitter.codeCopyRuntime.write(
                toFile: "\(scriptsDir)/_score-code-copy.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Write tab-group runtime if any page uses tab groups
        if rendered.contains(where: { $0.result.html.contains("data-tab-group") }) {
            try JSEmitter.tabGroupRuntime.write(
                toFile: "\(scriptsDir)/_score-tabs.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Compute JS scope-block chunking once for both file writing and link map.
        let reactiveEntries = rendered.filter { !$0.result.js.perPage.isEmpty }
        let uniqueReactivePages = Set(reactiveEntries.map(\.cssName)).count
        var jsChunked: JSChunkResult? =
            reactiveEntries.isEmpty
            ? nil
            : chunkJSScopeBlocks(rendered: rendered, totalPages: uniqueReactivePages)

        // Deduplicate JS: group Element scope blocks by usage pattern
        // (mirroring CSS chunking), write shared/chunk/page-specific files.
        try writeJSFiles(
            rendered: rendered,
            chunked: &jsChunked,
            scriptsDir: scriptsDir,
            minify: minify,
            fm: fm
        )

        // For each scope, track which pages use it and whether
        // the CSS block is identical across all of them. Only scopes
        // with identical CSS can be shared; scopes whose CSS varies
        // per page (e.g. wrapper components with different children)
        // are kept page-specific.
        let totalPages = Set(rendered.map(\.cssName)).count
        var scopePages: [String: Set<String>] = [:]
        var scopeCSS: [String: String] = [:]
        var divergentScopes: Set<String> = []
        for entry in rendered {
            for (scope, block) in entry.result.css.componentBlocks {
                scopePages[scope, default: []].insert(entry.cssName)
                if let existing = scopeCSS[scope] {
                    if existing != block {
                        divergentScopes.insert(scope)
                    }
                } else {
                    scopeCSS[scope] = block
                }
            }
        }

        // Divergent scopes stay page-specific
        var singlePageScopes: [String: [String]] = [:]
        for scope in divergentScopes {
            for entry in rendered where entry.result.css.componentBlocks[scope] != nil {
                singlePageScopes[entry.cssName, default: []].append(scope)
            }
            scopePages.removeValue(forKey: scope)
        }

        // Group uniform scopes by their exact page set
        var pageSetScopes: [Set<String>: [String]] = [:]
        for (scope, pages) in scopePages {
            pageSetScopes[pages, default: []].append(scope)
        }

        // Classify each group: shared (all pages), chunk (2+ pages), or page-unique
        var sharedCSS = ""
        var chunks: [ChunkFile] = []
        var usedChunkNames: Set<String> = []

        for (pageSet, scopes) in pageSetScopes {
            let sortedScopes = scopes.sorted()
            var blockCSS = ""
            for scope in sortedScopes {
                if let block = scopeCSS[scope] {
                    blockCSS.append(block)
                }
            }

            if pageSet.count == totalPages {
                sharedCSS.append(blockCSS)
            } else if pageSet.count >= 2 {
                let name = chunkName(for: pageSet, scopes: sortedScopes, avoiding: &usedChunkNames)
                chunks.append(ChunkFile(name: name, css: blockCSS, pages: pageSet))
            } else if let page = pageSet.first {
                singlePageScopes[page, default: []].append(contentsOf: sortedScopes)
            }
        }

        if !sharedCSS.isEmpty {
            try transform(sharedCSS, minify: minify, using: Minifier.minifyCSS).write(
                toFile: "\(stylesDir)/shared.css",
                atomically: true,
                encoding: .utf8
            )
        }

        for chunk in chunks {
            try transform(chunk.css, minify: minify, using: Minifier.minifyCSS).write(
                toFile: "\(stylesDir)/\(chunk.name).css",
                atomically: true,
                encoding: .utf8
            )
        }

        var pageHasCSS: Set<String> = []
        var cssFileMap: [String: String] = [:]
        var cssContentToFile: [String: String] = [:]
        for entry in rendered {
            var pageCSS = ""
            if let scopes = singlePageScopes[entry.cssName] {
                let scopeSet = Set(scopes)
                for scope in entry.result.css.scopeOrder where scopeSet.contains(scope) {
                    if let block = entry.result.css.componentBlocks[scope] {
                        pageCSS.append(block)
                    }
                }
            }
            pageCSS.append(entry.result.css.flat)

            if !pageCSS.isEmpty {
                pageHasCSS.insert(entry.cssName)
                if let existingFile = cssContentToFile[pageCSS] {
                    cssFileMap[entry.cssName] = existingFile
                } else {
                    cssContentToFile[pageCSS] = entry.cssName
                    cssFileMap[entry.cssName] = entry.cssName
                    try transform(pageCSS, minify: minify, using: Minifier.minifyCSS).write(
                        toFile: "\(stylesDir)/\(entry.cssName).css",
                        atomically: true,
                        encoding: .utf8
                    )
                }
            }
        }

        // Build JS link map: page name → actual script paths
        let jsLinkMap = buildJSLinkMap(rendered: rendered, chunked: jsChunked)

        // Write HTML with correct CSS and JS links
        for entry in rendered {
            var html = entry.result.html

            // Build the correct style links for this page.
            // Page-specific CSS loads before chunks to preserve cascade order:
            // wrapper components (e.g. Layout) are divergent and page-specific,
            // while their children may be uniform chunks loaded afterward.
            var styleLinks = ""
            if !sharedCSS.isEmpty {
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/shared.css\">\n")
            }
            if pageHasCSS.contains(entry.cssName) {
                let cssFileName = cssFileMap[entry.cssName] ?? entry.cssName
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/\(cssFileName).css\">\n")
            }
            for chunk in chunks.sorted(by: { $0.name < $1.name })
            where chunk.pages.contains(entry.cssName) {
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/\(chunk.name).css\">\n")
            }

            // Replace the placeholder per-page CSS link with the full link set
            html = html.replacingOccurrences(
                of: "<link rel=\"stylesheet\" href=\"/styles/\(entry.cssName).css\">\n",
                with: styleLinks
            )

            // Replace the placeholder per-page JS link with the deduplicated set
            if let scriptPaths = jsLinkMap[entry.cssName] {
                let scriptTags = scriptPaths.map {
                    "<script src=\"\($0)\" defer></script>"
                }.joined(separator: "\n")
                html = html.replacingOccurrences(
                    of: "<script src=\"/scripts/\(entry.cssName).js\" defer></script>",
                    with: scriptTags
                )
            }

            // Resolve asset references to fingerprinted paths
            if let manifest = assetManifest {
                for (original, fingerprinted) in manifest.entries {
                    html = html.replacingOccurrences(
                        of: "/assets/\(original)",
                        with: "/assets/\(fingerprinted)"
                    )
                }
            }

            let filePath = outputFilePath(for: entry.pagePath, in: outputDir)
            let dirPath = (filePath as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            try transform(html, minify: minify, using: Minifier.minifyHTML).write(
                toFile: filePath, atomically: true, encoding: .utf8
            )
        }

        try writeSitemap(
            pages: application.pages,
            baseURL: application.metadata?.baseURL,
            localization: localization,
            outputDirectory: outputDir
        )

        try writeRobotsTxt(
            baseURL: application.metadata?.baseURL,
            rules: application.robotsRules,
            controllers: application.controllers + plugins.flatMap(\.controllers),
            outputDirectory: outputDir
        )

        try writeErrorPage(
            application: application,
            outputDirectory: outputDir
        )
    }

    /// Writes deduplicated JS files. Element scope blocks are grouped by
    /// usage pattern (mirroring CSS chunking): blocks used on all reactive
    /// pages go into `shared.js`, blocks shared by a subset go into named
    /// chunks, and page-unique blocks stay in per-page files.
    private static func writeJSFiles(
        rendered: [RenderedPageEntry],
        chunked: inout JSChunkResult?,
        scriptsDir: String,
        minify: Bool,
        fm: FileManager
    ) throws {
        let reactiveEntries = rendered.filter { !$0.result.js.perPage.isEmpty }
        guard !reactiveEntries.isEmpty, var chunkedResult = chunked else { return }
        try fm.createDirectory(atPath: scriptsDir, withIntermediateDirectories: true)

        if !chunkedResult.sharedJS.isEmpty {
            try transform(chunkedResult.sharedJS, minify: minify, using: Minifier.minifyJS).write(
                toFile: "\(scriptsDir)/shared.js", atomically: true, encoding: .utf8)
        }

        for chunk in chunkedResult.chunks {
            try transform(chunk.js, minify: minify, using: Minifier.minifyJS).write(
                toFile: "\(scriptsDir)/\(chunk.name).js", atomically: true, encoding: .utf8)
        }

        // Compute per-page JS content and deduplicate identical files
        var contentToFile: [String: String] = [:]
        for entry in reactiveEntries {
            var pageJS = entry.result.js.pageLevel
            if let blocks = chunkedResult.pageBlocks[entry.cssName] {
                pageJS.append(blocks.joined())
            }
            guard !pageJS.isEmpty else { continue }

            if let existingFile = contentToFile[pageJS] {
                // Identical content already written — reuse the file
                chunkedResult.jsFileMap[entry.cssName] = existingFile
            } else {
                contentToFile[pageJS] = entry.cssName
                chunkedResult.jsFileMap[entry.cssName] = entry.cssName
                try transform(pageJS, minify: minify, using: Minifier.minifyJS).write(
                    toFile: "\(scriptsDir)/\(entry.cssName).js", atomically: true, encoding: .utf8)
            }
        }

        chunked = chunkedResult
    }

    private struct JSChunkResult {
        let sharedJS: String
        let chunks: [(name: String, js: String, pages: Set<String>)]
        let pageBlocks: [String: [String]]
        /// Maps page names with identical per-page JS to a single shared file name.
        /// Pages whose JS is unique map to themselves.
        var jsFileMap: [String: String]
    }

    private static func chunkJSScopeBlocks(
        rendered: [RenderedPageEntry],
        totalPages: Int
    ) -> JSChunkResult {
        var blockPages: [String: Set<String>] = [:]
        for entry in rendered {
            for block in entry.result.js.scopeBlocks {
                blockPages[block, default: []].insert(entry.cssName)
            }
        }

        var pageSetBlocks: [Set<String>: [String]] = [:]
        for (block, pages) in blockPages {
            pageSetBlocks[pages, default: []].append(block)
        }

        var sharedJS = ""
        var chunks: [(name: String, js: String, pages: Set<String>)] = []
        var pageBlocks: [String: [String]] = [:]
        var usedNames: Set<String> = ["shared"]

        for (pageSet, blocks) in pageSetBlocks {
            let combined = blocks.joined()
            if pageSet.count == totalPages {
                sharedJS.append(combined)
            } else if pageSet.count >= 2 {
                let name = chunkName(for: pageSet, scopes: [], avoiding: &usedNames)
                chunks.append((name: name, js: combined, pages: pageSet))
            } else if let page = pageSet.first {
                pageBlocks[page, default: []].append(contentsOf: blocks)
            }
        }

        return JSChunkResult(sharedJS: sharedJS, chunks: chunks, pageBlocks: pageBlocks, jsFileMap: [:])
    }

    /// Builds a map from page name to the list of actual JS script paths,
    /// accounting for scope-block deduplication.
    private static func buildJSLinkMap(rendered: [RenderedPageEntry], chunked: JSChunkResult?) -> [String: [String]] {
        let reactiveEntries = rendered.filter { !$0.result.js.perPage.isEmpty }
        guard !reactiveEntries.isEmpty, let chunked else { return [:] }

        var linkMap: [String: [String]] = [:]
        for entry in reactiveEntries {
            var links: [String] = []
            if !chunked.sharedJS.isEmpty {
                links.append("/scripts/shared.js")
            }
            for chunk in chunked.chunks.sorted(by: { $0.name < $1.name })
            where chunk.pages.contains(entry.cssName) {
                links.append("/scripts/\(chunk.name).js")
            }
            // Use the deduplicated file name when available
            let jsFileName = chunked.jsFileMap[entry.cssName] ?? entry.cssName
            let hasPageJS =
                !entry.result.js.pageLevel.isEmpty
                || chunked.pageBlocks[entry.cssName] != nil
            if hasPageJS {
                links.append("/scripts/\(jsFileName).js")
            }
            linkMap[entry.cssName] = links
        }
        return linkMap
    }

    /// Derives a chunk file name from the common prefix of page names,
    /// falling back to the first component scope in the chunk.
    private static func chunkName(
        for pages: Set<String>,
        scopes: [String],
        avoiding used: inout Set<String>
    ) -> String {
        let sorted = pages.sorted()
        var prefix = sorted[0]
        for page in sorted.dropFirst() {
            while !page.hasPrefix(prefix), !prefix.isEmpty {
                prefix = String(prefix.dropLast())
            }
        }
        while prefix.hasSuffix("-") {
            prefix = String(prefix.dropLast())
        }

        var name: String
        if !prefix.isEmpty {
            name = prefix
        } else if let first = scopes.sorted().first {
            name = first
        } else {
            name = "chunk"
        }

        if used.contains(name) {
            var index = 2
            while used.contains("\(name)-\(index)") { index += 1 }
            name = "\(name)-\(index)"
        }
        used.insert(name)
        return name
    }

    /// Writes a `404.html` file using the application's custom error page.
    ///
    /// Only produces output when ``Application/errorPage`` is set.
    /// Hosting platforms typically serve this file when no matching route
    /// is found.
    private static func writeErrorPage(
        application: some Application,
        outputDirectory: String
    ) throws {
        let context = ErrorContext(statusCode: 404, message: "Not Found", path: "/404")
        guard let errorPage = application.errorPage else { return }
        let body = errorPage.init(context: context)

        let html = PageRenderer.renderErrorBody(
            body,
            metadata: application.metadata,
            theme: application.theme
        )

        let minify = Environment.current == .production
        try transform(html, minify: minify, using: Minifier.minifyHTML).write(
            toFile: "\(outputDirectory)/404.html",
            atomically: true,
            encoding: .utf8
        )
    }

    /// Returns the input unchanged when `minify` is `false`, otherwise
    /// applies the given minification function.
    private static func transform(
        _ input: String,
        minify: Bool,
        using minifier: (String) -> String
    ) -> String {
        minify ? minifier(input) : input
    }

    /// Writes a `sitemap.xml` file listing all page URLs.
    ///
    /// Sitemaps require absolute URLs, so this method only produces output
    /// when the application metadata includes a ``Metadata/baseURL``.
    /// Status-code pages (e.g. `/404`) are excluded automatically.
    private static func writeSitemap(
        pages: [any Page],
        baseURL: String?,
        localization: Localization?,
        outputDirectory: String
    ) throws {
        guard let baseURL, !baseURL.isEmpty else { return }

        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL

        let localesToRender = Self.resolvedLocales(localization)

        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n")

        for locale in localesToRender {
            let isDefault = localization == nil || locale == localization?.defaultLocale
            let pathPrefix = isDefault ? "" : "/\(locale.identifier)"

            for page in pages {
                let path = page.path
                if isStatusPage(path) { continue }

                let fullPath = pathPrefix + path
                let loc = fullPath == "/" ? base + "/" : base + fullPath
                xml.append("  <url>\n    <loc>\(loc)</loc>\n  </url>\n")
            }
        }

        xml.append("</urlset>\n")

        try xml.write(
            toFile: "\(outputDirectory)/sitemap.xml",
            atomically: true,
            encoding: .utf8
        )
    }

    /// Writes a `robots.txt` file that allows all crawlers and points to
    /// the sitemap when a base URL is available.
    ///
    /// Only includes the `Sitemap` directive when the application metadata
    /// provides a ``Metadata/baseURL``, matching the sitemap generation
    /// condition.
    private static func writeRobotsTxt(
        baseURL: String?,
        rules: [String],
        controllers: [any Controller],
        outputDirectory: String
    ) throws {
        var content = "User-agent: *\nAllow: /\n"

        // Auto-disallow controller API paths
        var disallowed: Set<String> = []
        for controller in controllers {
            let base = controller.base
            if !base.isEmpty {
                let path = base.hasSuffix("/") ? base : base + "/"
                if disallowed.insert(path).inserted {
                    content.append("Disallow: \(path)\n")
                }
            }
        }

        for rule in rules {
            content.append("\(rule)\n")
        }

        if let baseURL, !baseURL.isEmpty {
            let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
            content.append("\nSitemap: \(base)/sitemap.xml\n")
        }

        try content.write(
            toFile: "\(outputDirectory)/robots.txt",
            atomically: true,
            encoding: .utf8
        )
    }

    /// Returns `true` when the path represents an HTTP status page
    /// (e.g. `/404`, `/500`) that should not appear in the sitemap.
    private static func isStatusPage(_ path: String) -> Bool {
        let segment = path.drop(while: { $0 == "/" })
        return segment.count == 3 && segment.allSatisfy(\.isNumber)
    }

    /// Returns the locales to render, defaulting to English when no
    /// localization is configured.
    private static func resolvedLocales(_ localization: Localization?) -> [SiteLocale] {
        if let localization {
            return localization.supportedLocales
        }
        return [SiteLocale("en")]
    }

    /// Maps a page path to a file path.
    ///
    /// - `/` → `index.html`
    /// - `/404` → `404.html`
    /// - `/about` → `about/index.html`
    /// - `/de` → `de/index.html`
    /// - `/docs/score` → `docs/score/index.html`
    private static func outputFilePath(for pagePath: String, in outputDir: String) -> String {
        if pagePath == "/" {
            return "\(outputDir)/index.html"
        }
        let trimmed = pagePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        // Error pages stay as flat files (e.g. 404.html)
        if let code = Int(trimmed), (400...599).contains(code) {
            return "\(outputDir)/\(trimmed).html"
        }
        return "\(outputDir)/\(trimmed)/index.html"
    }
}
