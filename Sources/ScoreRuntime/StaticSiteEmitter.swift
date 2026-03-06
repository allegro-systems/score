import Foundation
import ScoreAssets
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
/// Errors thrown by `StaticSiteEmitter` during static site generation.
public enum StaticSiteEmitterError: Error, CustomStringConvertible {
    /// A required bundled JS resource could not be found.
    case missingResource(String)

    public var description: String {
        switch self {
        case .missingResource(let name):
            return "Missing bundled resource '\(name).js' — the Score runtime package may be incomplete"
        }
    }
}

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
        let fingerprint = environment == .production

        let themeCSS = theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        let uiCSS = ThemeCSSEmitter.emitComponentCSS()
        let globalCSS = themeCSS.isEmpty ? uiCSS : themeCSS + "\n" + uiCSS

        var manifest: [String: String] = [:]

        let globalCSSFilename = fingerprintedFilename("as-global.css", content: globalCSS, enabled: fingerprint)
        try globalCSS.write(toFile: outputRoot + "/\(globalCSSFilename)", atomically: true, encoding: .utf8)
        manifest["as-global.css"] = globalCSSFilename

        var allScopedCSS = ""
        var allJS = ""
        var hasReactivity = false

        for page in application.pages {
            let (_, scopedCSS, js) = renderPage(page, metadata: metadata, theme: theme, environment: environment, assetManifest: [:])

            if !scopedCSS.isEmpty {
                allScopedCSS.append(scopedCSS)
            }

            if !js.isEmpty {
                hasReactivity = true
                allJS.append("// \(type(of: page).path)\n")
                allJS.append(js)
                allJS.append("\n")
            }
        }

        if !allScopedCSS.isEmpty {
            let groupCSSFilename = fingerprintedFilename("as-group-0.css", content: allScopedCSS, enabled: fingerprint)
            try allScopedCSS.write(toFile: outputRoot + "/\(groupCSSFilename)", atomically: true, encoding: .utf8)
            manifest["as-group-0.css"] = groupCSSFilename
        }

        if hasReactivity {
            let interactivityFilename = fingerprintedFilename("as-interactivity.js", content: allJS, enabled: fingerprint)
            try allJS.write(toFile: outputRoot + "/\(interactivityFilename)", atomically: true, encoding: .utf8)
            manifest["as-interactivity.js"] = interactivityFilename

            let polyfillContent = try readBundleResource("signal-polyfill")
            let polyfillFilename = fingerprintedFilename("signal-polyfill.js", content: polyfillContent, enabled: fingerprint)
            try polyfillContent.write(toFile: outputRoot + "/\(polyfillFilename)", atomically: true, encoding: .utf8)
            manifest["signal-polyfill.js"] = polyfillFilename

            let runtimeContent = try readBundleResource("score-runtime")
            let runtimeFilename = fingerprintedFilename("score-runtime.js", content: runtimeContent, enabled: fingerprint)
            try runtimeContent.write(toFile: outputRoot + "/\(runtimeFilename)", atomically: true, encoding: .utf8)
            manifest["score-runtime.js"] = runtimeFilename
        }

        for page in application.pages {
            let (html, _, _) = renderPage(page, metadata: metadata, theme: theme, environment: environment, assetManifest: manifest)

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
    }

    private static func renderPage(
        _ page: some Page,
        metadata: Metadata?,
        theme: (any Theme)?,
        environment: Environment,
        assetManifest: [String: String]
    ) -> (html: String, scopedCSS: String, js: String) {
        let result = PageRenderer.runPipeline(
            page: page,
            metadata: metadata,
            theme: theme,
            environment: environment
        )

        var rawJS = ""
        if !result.emitResult.script.isEmpty {
            rawJS = result.emitResult.script
                .replacingOccurrences(of: "<script>\n", with: "")
                .replacingOccurrences(of: "</script>", with: "")
        }

        let parts = DocumentAssembler.Parts(
            title: result.title,
            description: result.description,
            keywords: result.keywords,
            structuredData: result.structuredData,
            themeCSS: "",
            componentCSS: result.componentCSS,
            bodyHTML: result.bodyHTML,
            scripts: result.emitResult.script.isEmpty ? [] : [result.emitResult.script],
            activeTheme: result.activeTheme,
            externalAssets: true,
            assetManifest: assetManifest
        )

        return (DocumentAssembler.assemble(parts), result.componentCSS, rawJS)
    }

    private static func readBundleResource(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "js") else {
            throw StaticSiteEmitterError.missingResource(name)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private static func fingerprintedFilename(_ original: String, content: String, enabled: Bool) -> String {
        guard enabled else { return original }
        return AssetFingerprint.fingerprintedName(original: original, data: Data(content.utf8))
    }
}
