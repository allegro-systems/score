import ScoreHTML

/// Renders a development error overlay as HTML.
public struct ErrorOverlay: Sendable {

    /// A stack frame for display in the error overlay.
    public struct Frame: Sendable {
        public let label: String
        public let file: String
        public let line: Int
        public let column: Int?

        public init(label: String, file: String, line: Int, column: Int? = nil) {
            self.label = label
            self.file = file
            self.line = line
            self.column = column
        }
    }

    private init() {}

    /// Renders an error as an HTML page.
    ///
    /// In development, shows full error details. In production, shows a
    /// generic "Something went wrong" message without leaking internals.
    public static func render(
        _ error: any Error,
        path: String,
        frames: [Frame] = [],
        environment: Environment
    ) -> String {
        guard environment == .development else {
            return genericErrorPage()
        }

        let typeName = String(describing: type(of: error)).htmlEscaped
        let message = String(describing: error).htmlEscaped
        let escapedPath = path.htmlEscaped

        var html = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
            <meta charset="utf-8">
            <title>Score Development Error</title>
            <style>
            body { font-family: system-ui, sans-serif; padding: 2rem; background: #1a1a2e; color: #e0e0e0; }
            .error-box { background: #16213e; border: 1px solid #e94560; border-radius: 8px; padding: 1.5rem; margin-bottom: 1rem; }
            .error-type { color: #e94560; font-weight: bold; }
            .error-path { color: #0f3460; }
            pre { background: #0f3460; padding: 1rem; border-radius: 4px; overflow-x: auto; }
            a { color: #e94560; }
            </style>
            </head>
            <body>
            <h1>Score Development Error</h1>
            <div class="error-box">
            <p class="error-type">\(typeName)</p>
            <p>\(message)</p>
            <p>Path: <code>\(escapedPath)</code></p>
            </div>
            """

        if !frames.isEmpty {
            html.append("<h2>Stack Trace</h2>\n<pre>")
            for frame in frames {
                let location: String
                if let col = frame.column {
                    location = "\(frame.file.htmlEscaped):\(frame.line):\(col)"
                } else {
                    location = "\(frame.file.htmlEscaped):\(frame.line)"
                }
                let vscodeLink = "vscode://file/\(frame.file):\(frame.line)"
                html.append("<a href=\"\(vscodeLink)\">\(frame.label.htmlEscaped)</a> at \(location)\n")
            }
            html.append("</pre>")
        }

        html.append("</body>\n</html>")
        return html
    }

    private static func genericErrorPage() -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head><meta charset="utf-8"><title>Error</title></head>
        <body><h1>Something went wrong</h1><p>An unexpected error occurred.</p></body>
        </html>
        """
    }
}
