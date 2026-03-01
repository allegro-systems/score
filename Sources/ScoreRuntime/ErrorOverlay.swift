/// Renders a full-page error overlay for development mode.
///
/// When a server-side render throws in development, `ErrorOverlay` produces
/// a styled HTML page showing the error type, message, and an optional
/// stack trace with file/line annotations. Clickable frames open the source
/// in the editor via `vscode://` deep links.
///
/// Colours use the Allegro handbook design system in OKLCH — dark surface
/// with cool blue-tinted neutrals (hue 240) and the destructive role
/// for error highlights.
///
/// In production mode, ``render(_:environment:)`` returns a generic error
/// page with no implementation details.
public enum ErrorOverlay: Sendable {

    /// A single frame in a source-mapped stack trace.
    public struct Frame: Sendable {
        /// The function or context label.
        public let label: String
        /// The Swift source file path.
        public let file: String
        /// The line number in the source file.
        public let line: Int
        /// The column number, if available.
        public let column: Int?

        public init(label: String, file: String, line: Int, column: Int? = nil) {
            self.label = label
            self.file = file
            self.line = line
            self.column = column
        }
    }

    // MARK: - Allegro Design Tokens (OKLCH)

    /// Dark surface — oklch(0.17, 0.014, 240).
    private static let surface = "oklch(0.17 0.014 240)"
    /// Light text — oklch(0.93, 0.004, 240).
    private static let text = "oklch(0.93 0.004 240)"
    /// Border — oklch(0.26, 0.012, 240).
    private static let border = "oklch(0.26 0.012 240)"
    /// Accent — oklch(0.68, 0.13, 215).
    private static let accent = "oklch(0.68 0.13 215)"
    /// Muted — oklch(0.58, 0.006, 240).
    private static let muted = "oklch(0.58 0.006 240)"
    /// Destructive — oklch(0.65, 0.2, 25).
    private static let destructive = "oklch(0.65 0.2 25)"
    /// Elevated surface — slightly lighter than surface.
    private static let surfaceElevated = "oklch(0.22 0.012 240)"

    /// Renders an error overlay HTML document.
    ///
    /// - Parameters:
    ///   - error: The error that occurred during rendering.
    ///   - path: The request path that triggered the error.
    ///   - frames: Optional source-mapped stack frames.
    ///   - environment: The current environment.
    /// - Returns: A complete HTML document string.
    public static func render(
        _ error: any Error,
        path: String = "/",
        frames: [Frame] = [],
        environment: Environment
    ) -> String {
        guard environment == .development else {
            return productionErrorPage()
        }

        let errorType = String(describing: type(of: error))
        let errorMessage = String(describing: error)

        var html = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n"
        html.append("<meta charset=\"utf-8\">\n")
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")
        html.append("<title>Score Error</title>\n")
        html.append("<style>\n")
        html.append("*{margin:0;padding:0;box-sizing:border-box}\n")
        appendBodyStyle(&html)
        html.append(".container{max-width:720px;margin:0 auto}\n")
        html.append(".header{display:flex;align-items:center;gap:12px;margin-bottom:24px}\n")
        appendLogoStyle(&html)
        html.append(".title{font-size:14px;color:\(muted);font-weight:400}\n")
        appendErrorBoxStyle(&html)
        html.append(".error-type{color:\(destructive);font-size:13px;font-weight:600;margin-bottom:6px}\n")
        appendErrorMsgStyle(&html)
        html.append(".path-label{font-size:12px;color:\(muted);margin-bottom:16px}\n")
        html.append(".path-label code{color:\(accent)}\n")
        html.append(".stack{background:\(surfaceElevated);border-radius:8px;overflow:hidden}\n")
        appendStackTitleStyle(&html)
        html.append(".frame{padding:10px 16px;border-bottom:1px solid \(border);font-size:13px}\n")
        html.append(".frame:last-child{border-bottom:none}\n")
        html.append(".frame:hover{background:\(surface)}\n")
        html.append(".frame-label{color:\(text);font-weight:500}\n")
        appendFrameFileStyle(&html)
        html.append(".frame-file:hover{text-decoration:underline}\n")
        html.append("</style>\n</head>\n<body>\n")
        html.append("<div class=\"container\">\n")
        html.append("<div class=\"header\">\n")
        html.append("<div class=\"logo\">S</div>\n")
        html.append("<div class=\"title\">Score Development Error</div>\n")
        html.append("</div>\n")
        html.append("<div class=\"path-label\">Error at <code>")
        html.append("\(escapeHTML(path))</code></div>\n")
        html.append("<div class=\"error-box\">\n")
        html.append("<div class=\"error-type\">\(escapeHTML(errorType))</div>\n")
        html.append("<div class=\"error-msg\">\(escapeHTML(errorMessage))</div>\n")
        html.append("</div>\n")

        if !frames.isEmpty {
            html.append("<div class=\"stack\">\n")
            html.append("<div class=\"stack-title\">Stack Trace</div>\n")
            for frame in frames {
                let columnSuffix = frame.column.map { ":\($0)" } ?? ""
                let vscodeURL =
                    "vscode://file/\(frame.file):\(frame.line)"
                    + columnSuffix
                html.append("<div class=\"frame\">\n")
                html.append("<div class=\"frame-label\">")
                html.append("\(escapeHTML(frame.label))</div>\n")
                html.append("<a class=\"frame-file\" href=\"")
                html.append("\(escapeHTML(vscodeURL))\">")
                html.append("\(escapeHTML(frame.file)):\(frame.line)")
                if let col = frame.column {
                    html.append(":\(col)")
                }
                html.append("</a>\n</div>\n")
            }
            html.append("</div>\n")
        }

        html.append("</div>\n</body>\n</html>\n")
        return html
    }

    // MARK: - Style Helpers

    private static func appendBodyStyle(_ html: inout String) {
        let fontStack =
            "ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,sans-serif"
        html.append("body{font-family:\(fontStack);")
        html.append("background:\(surface);color:\(text);")
        html.append("padding:40px 20px;min-height:100vh}\n")
    }

    private static func appendLogoStyle(_ html: inout String) {
        html.append(".logo{width:32px;height:32px;border-radius:8px;")
        html.append("background:\(destructive);color:\(text);")
        html.append("display:flex;align-items:center;justify-content:center;")
        html.append("font-weight:700;font-size:18px}\n")
    }

    private static func appendErrorBoxStyle(_ html: inout String) {
        html.append(".error-box{background:\(surfaceElevated);")
        html.append("border:1px solid \(destructive);")
        html.append("border-radius:8px;padding:20px;margin-bottom:20px}\n")
    }

    private static func appendErrorMsgStyle(_ html: inout String) {
        let monoStack = "ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace"
        html.append(".error-msg{font-size:15px;font-family:\(monoStack);")
        html.append("color:\(text);white-space:pre-wrap;")
        html.append("word-break:break-word;line-height:1.5}\n")
    }

    private static func appendStackTitleStyle(_ html: inout String) {
        html.append(".stack-title{padding:12px 16px;font-size:12px;")
        html.append("font-weight:600;color:\(muted);")
        html.append("border-bottom:1px solid \(border)}\n")
    }

    private static func appendFrameFileStyle(_ html: inout String) {
        let monoStack = "ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace"
        html.append(".frame-file{color:\(accent);text-decoration:none;")
        html.append("font-family:\(monoStack);font-size:12px;")
        html.append("display:block;margin-top:2px}\n")
    }

    // MARK: - Production Error Page

    private static func productionErrorPage() -> String {
        var html = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n"
        html.append("<meta charset=\"utf-8\">\n")
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")
        html.append("<title>Server Error</title>\n")
        html.append("<style>body{font-family:system-ui,sans-serif;")
        html.append("display:flex;align-items:center;justify-content:center;")
        html.append("min-height:100vh;margin:0;")
        html.append("background:oklch(0.97 0 0);color:oklch(0.16 0 0)}")
        html.append("h1{font-size:1.5rem;font-weight:400}</style>\n")
        html.append("</head>\n<body><h1>Something went wrong.</h1></body>\n</html>\n")
        return html
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
