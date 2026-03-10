import Foundation
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

    /// Renders all pages and writes them, along with external CSS and JS files,
    /// to the application's output directory.
    ///
    /// Component CSS is chunked by usage pattern: components used on all pages
    /// go into `shared.css`, components shared by a subset of pages go into
    /// named chunk files (e.g. `docs-score.css`), and page-unique styles stay
    /// in per-page files.
    ///
    /// JavaScript is externalized: the Score signals runtime is written to
    /// `score.js` (shared across all reactive pages), and per-page declarations
    /// go into `/scripts/{page}.js`.
    ///
    /// The output directory is wiped clean before each emission so stale
    /// files from previous builds never linger.
    public static func emit(application: some Application) throws {
        let outputDir = application.outputDirectory
        let fm = FileManager.default

        if fm.fileExists(atPath: outputDir) {
            try fm.removeItem(atPath: outputDir)
        }
        try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        let stylesDir = "\(outputDir)/styles"
        let scriptsDir = "\(outputDir)/scripts"
        try fm.createDirectory(atPath: stylesDir, withIntermediateDirectories: true)

        let globalCSS = application.theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        try globalCSS.write(
            toFile: "\(outputDir)/global.css",
            atomically: true,
            encoding: .utf8
        )

        // Render all pages with placeholder CSS and JS links.
        // The actual links are rewritten after chunk computation.
        var rendered: [RenderedPageEntry] = []
        var anyPageNeedsRuntime = false

        for page in application.pages {
            let pagePath = page.path
            let cssName = RequestHandler.cssFileName(for: pagePath)

            // Build script links: runtime + per-page placeholder
            var scriptLinks: [String] = []
            let jsResult = JSEmitter.emitPageScript(page: page)
            if !jsResult.pageJS.isEmpty {
                if jsResult.needsRuntime {
                    scriptLinks.append("/score.js")
                    anyPageNeedsRuntime = true
                }
                scriptLinks.append("/scripts/\(cssName).js")
            }

            let result = PageRenderer.render(
                page: page,
                metadata: application.metadata,
                theme: application.theme,
                cssLinks: ["/global.css", "/styles/\(cssName).css"],
                scriptLinks: scriptLinks
            )

            rendered.append(RenderedPageEntry(pagePath: pagePath, cssName: cssName, result: result))
        }

        // Write shared Score runtime
        if anyPageNeedsRuntime {
            try JSEmitter.clientRuntime.write(
                toFile: "\(outputDir)/score.js",
                atomically: true,
                encoding: .utf8
            )
        }

        // Deduplicate JS: group pages by identical content, write shared
        // files for groups used by multiple pages.
        try writeJSFiles(
            rendered: rendered,
            scriptsDir: scriptsDir,
            fm: fm
        )

        // For each scope, track which pages use it
        let totalPages = rendered.count
        var scopePages: [String: Set<String>] = [:]
        for entry in rendered {
            for scope in entry.result.componentBlocks.keys {
                scopePages[scope, default: []].insert(entry.cssName)
            }
        }

        // Group scopes by their exact page set
        var pageSetScopes: [Set<String>: [String]] = [:]
        for (scope, pages) in scopePages {
            pageSetScopes[pages, default: []].append(scope)
        }

        // Classify each group: shared (all pages), chunk (2+ pages), or page-unique
        var sharedCSS = ""
        var chunks: [ChunkFile] = []
        var singlePageScopes: [String: [String]] = [:]
        var usedChunkNames: Set<String> = []

        for (pageSet, scopes) in pageSetScopes {
            let sortedScopes = scopes.sorted()
            var blockCSS = ""
            for scope in sortedScopes {
                for entry in rendered where entry.result.componentBlocks[scope] != nil {
                    if let block = entry.result.componentBlocks[scope] {
                        blockCSS.append(block)
                        break
                    }
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

        // Write shared.css
        if !sharedCSS.isEmpty {
            try sharedCSS.write(
                toFile: "\(stylesDir)/shared.css",
                atomically: true,
                encoding: .utf8
            )
        }

        // Write chunk files
        for chunk in chunks {
            try chunk.css.write(
                toFile: "\(stylesDir)/\(chunk.name).css",
                atomically: true,
                encoding: .utf8
            )
        }

        // Build and write per-page CSS (page-unique scopes + flat CSS)
        var pageHasCSS: Set<String> = []
        for entry in rendered {
            var pageCSS = ""
            if let scopes = singlePageScopes[entry.cssName] {
                for scope in scopes.sorted() {
                    if let block = entry.result.componentBlocks[scope] {
                        pageCSS.append(block)
                    }
                }
            }
            pageCSS.append(entry.result.flatCSS)

            if !pageCSS.isEmpty {
                pageHasCSS.insert(entry.cssName)
                try pageCSS.write(
                    toFile: "\(stylesDir)/\(entry.cssName).css",
                    atomically: true,
                    encoding: .utf8
                )
            }
        }

        // Build JS link map: page name → actual script path
        let jsLinkMap = buildJSLinkMap(rendered: rendered)

        // Write HTML with correct CSS and JS links
        for entry in rendered {
            var html = entry.result.html

            // Build the correct style links for this page
            var styleLinks = ""
            if !sharedCSS.isEmpty {
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/shared.css\">\n")
            }
            for chunk in chunks.sorted(by: { $0.name < $1.name })
            where chunk.pages.contains(entry.cssName) {
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/\(chunk.name).css\">\n")
            }
            if pageHasCSS.contains(entry.cssName) {
                styleLinks.append(
                    "<link rel=\"stylesheet\" href=\"/styles/\(entry.cssName).css\">\n")
            }

            // Replace the placeholder per-page CSS link with the full link set
            html = html.replacingOccurrences(
                of: "<link rel=\"stylesheet\" href=\"/styles/\(entry.cssName).css\">\n",
                with: styleLinks
            )

            // Replace the placeholder per-page JS link with the deduplicated one
            if let actualPath = jsLinkMap[entry.cssName] {
                html = html.replacingOccurrences(
                    of: "<script src=\"/scripts/\(entry.cssName).js\"></script>",
                    with: "<script src=\"\(actualPath)\"></script>"
                )
            }

            let filePath = outputFilePath(for: entry.pagePath, in: outputDir)
            let dirPath = (filePath as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            try html.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }

    /// Writes deduplicated JS files. Pages with identical JS content share a
    /// single file instead of getting individual copies.
    private static func writeJSFiles(
        rendered: [RenderedPageEntry],
        scriptsDir: String,
        fm: FileManager
    ) throws {
        let groups = jsContentGroups(from: rendered)
        guard !groups.isEmpty else { return }
        try fm.createDirectory(atPath: scriptsDir, withIntermediateDirectories: true)

        for (name, js) in groups {
            try js.write(
                toFile: "\(scriptsDir)/\(name).js",
                atomically: true,
                encoding: .utf8
            )
        }
    }

    /// Builds a map from page name to actual JS file path, accounting for
    /// deduplication of identical content.
    private static func buildJSLinkMap(rendered: [RenderedPageEntry]) -> [String: String] {
        var contentPages: [String: [String]] = [:]
        for entry in rendered where !entry.result.pageJS.isEmpty {
            contentPages[entry.result.pageJS, default: []].append(entry.cssName)
        }

        var usedNames: Set<String> = []
        var linkMap: [String: String] = [:]

        for (_, pages) in contentPages {
            let name: String
            if pages.count == 1 {
                name = pages[0]
            } else {
                name = chunkName(for: Set(pages), scopes: [], avoiding: &usedNames)
            }

            for page in pages {
                linkMap[page] = "/scripts/\(name).js"
            }
        }
        return linkMap
    }

    /// Groups pages by identical JS content, returning `(fileName, jsContent)` pairs.
    private static func jsContentGroups(
        from rendered: [RenderedPageEntry]
    ) -> [(name: String, js: String)] {
        var contentPages: [String: [String]] = [:]
        for entry in rendered where !entry.result.pageJS.isEmpty {
            contentPages[entry.result.pageJS, default: []].append(entry.cssName)
        }

        var usedNames: Set<String> = []
        var result: [(name: String, js: String)] = []

        for (js, pages) in contentPages {
            let name: String
            if pages.count == 1 {
                name = pages[0]
            } else {
                name = chunkName(for: Set(pages), scopes: [], avoiding: &usedNames)
            }
            result.append((name: name, js: js))
        }
        return result
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
            name = "shared"
        }

        if used.contains(name) {
            var index = 2
            while used.contains("\(name)-\(index)") { index += 1 }
            name = "\(name)-\(index)"
        }
        used.insert(name)
        return name
    }

    /// Maps a page path to a file path.
    ///
    /// - `/` → `index.html`
    /// - `/404` → `404.html`
    /// - `/docs/score` → `docs/score.html`
    /// - `/docs/score/application` → `docs/score/application.html`
    private static func outputFilePath(for pagePath: String, in outputDir: String) -> String {
        if pagePath == "/" {
            return "\(outputDir)/index.html"
        }
        let trimmed = pagePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(outputDir)/\(trimmed).html"
    }
}
