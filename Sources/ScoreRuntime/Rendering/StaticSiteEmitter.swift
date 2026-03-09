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

    /// Renders all pages and writes them, along with external CSS files, to the
    /// application's output directory.
    ///
    /// The output directory is wiped clean before each emission so stale
    /// files from previous builds never linger.
    public static func emit(application: some Application) throws {
        let outputDir = application.outputDirectory
        let fm = FileManager.default

        // Clean previous output
        if fm.fileExists(atPath: outputDir) {
            try fm.removeItem(atPath: outputDir)
        }
        try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

        // Create styles directory
        let stylesDir = "\(outputDir)/styles"
        try fm.createDirectory(atPath: stylesDir, withIntermediateDirectories: true)

        // Emit global CSS (theme tokens)
        let globalCSS = application.theme.map { ThemeCSSEmitter.emit($0) } ?? ""
        try globalCSS.write(
            toFile: "\(outputDir)/global.css",
            atomically: true,
            encoding: .utf8
        )

        // Emit pages with per-page CSS files
        for page in application.pages {
            let pagePath = page.path
            let cssName = RequestHandler.cssFileName(for: pagePath)
            let cssLinks = ["/global.css", "/styles/\(cssName).css"]

            let result = PageRenderer.render(
                page: page,
                metadata: application.metadata,
                theme: application.theme,
                cssLinks: cssLinks
            )

            // Write per-page component CSS
            if !result.componentCSS.isEmpty {
                try result.componentCSS.write(
                    toFile: "\(stylesDir)/\(cssName).css",
                    atomically: true,
                    encoding: .utf8
                )
            }

            // Write HTML
            let filePath = outputFilePath(for: pagePath, in: outputDir)
            let dirPath = (filePath as NSString).deletingLastPathComponent
            try fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            try result.html.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
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
