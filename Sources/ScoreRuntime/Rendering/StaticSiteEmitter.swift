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

/// Emits a static site from an `Application` to disk.
public struct StaticSiteEmitter: Sendable {

    private init() {}

    /// Renders all pages and writes them, along with global CSS, to the
    /// application's output directory.
    public static func emit(application: some Application) throws {
        let outputDir = application.outputDirectory
        let staticDir = "\(outputDir)/static"

        try FileManager.default.createDirectory(
            atPath: staticDir,
            withIntermediateDirectories: true
        )

        // Emit global CSS (theme + component tokens)
        let themeCSS = application.theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        let componentCSS = emitComponentTokens()
        let globalCSS = themeCSS + componentCSS
        try globalCSS.write(
            toFile: "\(staticDir)/as-global.css",
            atomically: true,
            encoding: .utf8
        )

        // Emit pages
        for page in application.pages {
            let pagePath = type(of: page).path
            let html = PageRenderer.render(
                page: page,
                metadata: application.metadata,
                theme: application.theme
            )

            // Inject external CSS reference
            let htmlWithCSS = injectCSSLink(into: html)

            let filePath = outputFilePath(for: pagePath, in: staticDir)
            let dirPath = (filePath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(
                atPath: dirPath,
                withIntermediateDirectories: true
            )
            try htmlWithCSS.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }

    private static func emitComponentTokens() -> String {
        // Emit standard data-component CSS custom properties
        return "\n[data-component] {\n  /* Component token defaults */\n}\n"
    }

    private static func injectCSSLink(into html: String) -> String {
        html.replacingOccurrences(
            of: "</head>",
            with: "<link rel=\"stylesheet\" href=\"as-global.css\">\n</head>"
        )
    }

    private static func outputFilePath(for pagePath: String, in staticDir: String) -> String {
        if pagePath == "/" {
            return "\(staticDir)/index.html"
        }
        let trimmed = pagePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(staticDir)/\(trimmed)/index.html"
    }
}
