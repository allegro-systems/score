import Foundation

/// Serves static files from a directory with proper MIME types.
public struct StaticFileHandler: Sendable {

    private init() {}

    /// Returns the MIME type for a file extension.
    public static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "js", "mjs": return "application/javascript; charset=utf-8"
        case "json", "map": return "application/json"
        case "xml": return "application/xml"
        case "wasm": return "application/wasm"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "ico": return "image/x-icon"
        case "webp": return "image/webp"
        case "avif": return "image/avif"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        case "txt": return "text/plain; charset=utf-8"
        default: return "application/octet-stream"
        }
    }

    /// Serves a file from the given directory.
    ///
    /// Returns `nil` if the path is empty, attempts directory traversal,
    /// or the file does not exist.
    public static func serve(
        relativePath: String,
        from directory: String
    ) -> (Data, String)? {
        guard !relativePath.isEmpty else { return nil }
        guard !relativePath.contains("..") else { return nil }

        let fullPath = (directory as NSString).appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: fullPath) else { return nil }

        guard let data = FileManager.default.contents(atPath: fullPath) else { return nil }

        let ext = (relativePath as NSString).pathExtension
        let contentType = mimeType(for: ext)

        return (data, contentType)
    }
}
