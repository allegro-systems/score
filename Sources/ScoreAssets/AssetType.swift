/// Describes a known asset file type and its associated MIME type.
///
/// `AssetType` provides a static catalog of common web asset types —
/// stylesheets, scripts, images, fonts, and media — along with their
/// canonical MIME types. Use ``detect(from:)`` to look up the type for
/// a given filename, and ``isCompressible`` to determine whether the
/// asset benefits from gzip or other transfer encoding.
public struct AssetType: Sendable, Hashable {

    /// The file extension associated with this asset type, without a leading dot.
    public let fileExtension: String

    /// The canonical MIME type for this asset type (e.g. `"text/css"`).
    public let mimeType: String

    /// CSS stylesheet.
    public static let css = AssetType(fileExtension: "css", mimeType: "text/css")

    /// JavaScript source.
    public static let js = AssetType(fileExtension: "js", mimeType: "application/javascript")

    /// JSON data.
    public static let json = AssetType(fileExtension: "json", mimeType: "application/json")

    /// HTML document.
    public static let html = AssetType(fileExtension: "html", mimeType: "text/html")

    /// PNG image.
    public static let png = AssetType(fileExtension: "png", mimeType: "image/png")

    /// JPEG image (`.jpg` extension).
    public static let jpg = AssetType(fileExtension: "jpg", mimeType: "image/jpeg")

    /// JPEG image (`.jpeg` extension).
    public static let jpeg = AssetType(fileExtension: "jpeg", mimeType: "image/jpeg")

    /// GIF image.
    public static let gif = AssetType(fileExtension: "gif", mimeType: "image/gif")

    /// SVG vector image.
    public static let svg = AssetType(fileExtension: "svg", mimeType: "image/svg+xml")

    /// WebP image.
    public static let webp = AssetType(fileExtension: "webp", mimeType: "image/webp")

    /// AVIF image.
    public static let avif = AssetType(fileExtension: "avif", mimeType: "image/avif")

    /// ICO icon.
    public static let ico = AssetType(fileExtension: "ico", mimeType: "image/x-icon")

    /// WOFF font.
    public static let woff = AssetType(fileExtension: "woff", mimeType: "font/woff")

    /// WOFF2 font.
    public static let woff2 = AssetType(fileExtension: "woff2", mimeType: "font/woff2")

    /// TrueType font.
    public static let ttf = AssetType(fileExtension: "ttf", mimeType: "font/ttf")

    /// OpenType font.
    public static let otf = AssetType(fileExtension: "otf", mimeType: "font/otf")

    /// Web app manifest.
    public static let webmanifest = AssetType(fileExtension: "webmanifest", mimeType: "application/manifest+json")

    /// XML document.
    public static let xml = AssetType(fileExtension: "xml", mimeType: "application/xml")

    /// Plain text file.
    public static let txt = AssetType(fileExtension: "txt", mimeType: "text/plain")

    /// PDF document.
    public static let pdf = AssetType(fileExtension: "pdf", mimeType: "application/pdf")

    /// MP4 video.
    public static let mp4 = AssetType(fileExtension: "mp4", mimeType: "video/mp4")

    /// WebM video.
    public static let webm = AssetType(fileExtension: "webm", mimeType: "video/webm")

    /// MP3 audio.
    public static let mp3 = AssetType(fileExtension: "mp3", mimeType: "audio/mpeg")

    /// WebAssembly binary.
    public static let wasm = AssetType(fileExtension: "wasm", mimeType: "application/wasm")

    /// All known asset types, indexed by file extension for fast lookup.
    private static let knownTypes: [String: AssetType] = {
        let all: [AssetType] = [
            .css, .js, .json, .html, .png, .jpg, .jpeg, .gif, .svg, .webp,
            .avif, .ico, .woff, .woff2, .ttf, .otf, .webmanifest, .xml,
            .txt, .pdf, .mp4, .webm, .mp3, .wasm,
        ]
        return Dictionary(uniqueKeysWithValues: all.map { ($0.fileExtension, $0) })
    }()

    /// Detects the asset type from a filename's extension.
    ///
    /// The lookup is case-insensitive and matches the portion of the filename
    /// after the last dot.
    ///
    /// - Parameter filename: A filename or path (e.g. `"app.min.js"`).
    /// - Returns: The matching ``AssetType``, or `nil` if the extension is
    ///   not recognized.
    public static func detect(from filename: String) -> AssetType? {
        guard let dotIndex = filename.lastIndex(of: ".") else { return nil }
        let ext = String(filename[filename.index(after: dotIndex)...]).lowercased()
        return knownTypes[ext]
    }

    /// Whether this asset type is compressible (text-based).
    ///
    /// Text-based formats such as CSS, JavaScript, HTML, SVG, JSON, and XML
    /// typically compress well with gzip. Binary formats like PNG, JPEG, and
    /// WOFF2 are already compressed and gain little from additional encoding.
    public var isCompressible: Bool {
        switch fileExtension {
        case "css", "js", "json", "html", "svg", "xml", "txt", "webmanifest", "wasm":
            return true
        default:
            return false
        }
    }
}
