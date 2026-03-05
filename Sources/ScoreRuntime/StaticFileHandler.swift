import Foundation

/// Serves static files from a directory on disk.
///
/// `StaticFileHandler` reads files from a base directory and determines
/// their MIME type from the file extension. It rejects paths containing
/// directory traversal sequences for security.
struct StaticFileHandler {

    /// Attempts to serve a file at `relativePath` from the given `directory`.
    ///
    /// - Parameters:
    ///   - relativePath: The path relative to the static root (no leading slash).
    ///   - directory: The absolute path to the static file directory.
    /// - Returns: A tuple of file data and content type, or `nil` if the
    ///   file cannot be served.
    static func serve(relativePath: String, from directory: String) -> (Data, String)? {
        guard !relativePath.isEmpty else { return nil }

        let baseURL = URL(fileURLWithPath: directory).standardized
        let fullPath = baseURL.appendingPathComponent(relativePath).standardized.path
        guard fullPath.hasPrefix(baseURL.path) else { return nil }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory),
            !isDirectory.boolValue
        else {
            return nil
        }

        guard let data = FileManager.default.contents(atPath: fullPath) else { return nil }

        let ext = (relativePath as NSString).pathExtension.lowercased()
        return (data, mimeType(for: ext))
    }

    /// Returns the MIME type for a given file extension.
    static func mimeType(for ext: String) -> String {
        switch ext {
        case "html": return "text/html; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "js": return "application/javascript; charset=utf-8"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "ico": return "image/x-icon"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        case "webp": return "image/webp"
        case "avif": return "image/avif"
        case "xml": return "application/xml"
        case "txt": return "text/plain; charset=utf-8"
        case "map": return "application/json"
        case "wasm": return "application/wasm"
        default: return "application/octet-stream"
        }
    }
}
