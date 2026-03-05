import ScoreCore

/// Assembles a complete HTML document from rendered parts.
///
/// `DocumentAssembler` is a pure-function namespace that merges a page's
/// rendered HTML body, collected CSS, theme custom properties, metadata,
/// and optional script tags into a valid `<!DOCTYPE html>` document.
///
/// ### Example
///
/// ```swift
/// let html = DocumentAssembler.assemble(
///     title: "Home | My App",
///     description: "Welcome to my app.",
///     keywords: ["swift", "web"],
///     themeCSS: themeProperties,
///     componentCSS: collectedStylesheet,
///     bodyHTML: renderedBody,
///     scripts: []
/// )
/// ```
public struct DocumentAssembler: Sendable {

    private init() {}

    /// The parts needed to assemble a complete HTML document.
    public struct Parts: Sendable {

        /// The composed `<title>` content.
        public var title: String?

        /// The meta description content.
        public var description: String?

        /// The meta keywords content.
        public var keywords: [String]

        /// JSON-LD structured data payloads.
        public var structuredData: [String]

        /// CSS custom properties from the theme.
        public var themeCSS: String

        /// Scoped component CSS from `CSSCollector`.
        public var componentCSS: String

        /// The rendered HTML body content.
        public var bodyHTML: String

        /// Script tags to emit before `</body>`.
        public var scripts: [String]

        /// The active named theme, emitted as `data-theme` on `<html>`.
        public var activeTheme: String?

        /// When `true`, emit external `<link>` and `<script src>` references
        /// instead of inline `<style>` and `<script>` blocks. Used by the
        /// static site emitter to produce files that reference `as-global.css`,
        /// `as-group-0.css`, and `as-interactivity.js`.
        public var externalAssets: Bool

        /// Creates a new parts value.
        public init(
            title: String? = nil,
            description: String? = nil,
            keywords: [String] = [],
            structuredData: [String] = [],
            themeCSS: String = "",
            componentCSS: String = "",
            bodyHTML: String = "",
            scripts: [String] = [],
            activeTheme: String? = nil,
            externalAssets: Bool = false
        ) {
            self.title = title
            self.description = description
            self.keywords = keywords
            self.structuredData = structuredData
            self.themeCSS = themeCSS
            self.componentCSS = componentCSS
            self.bodyHTML = bodyHTML
            self.scripts = scripts
            self.activeTheme = activeTheme
            self.externalAssets = externalAssets
        }
    }

    /// Composes a document title from page and site components.
    ///
    /// - Parameters:
    ///   - pageTitle: The page-specific title.
    ///   - separator: The separator between page and site titles.
    ///   - site: The site name.
    /// - Returns: The composed title string, or `nil` if both are absent.
    public static func composeTitle(
        page pageTitle: String?,
        separator: String,
        site: String?
    ) -> String? {
        switch (pageTitle, site) {
        case (let page?, let site?): return "\(page)\(separator)\(site)"
        case (let page?, nil): return page
        case (nil, let site?): return site
        case (nil, nil): return nil
        }
    }

    /// Assembles a complete HTML document from the given parts.
    ///
    /// - Parameter parts: The document parts to assemble.
    /// - Returns: A complete `<!DOCTYPE html>` string.
    public static func assemble(_ parts: Parts) -> String {
        var htmlTag = "<html lang=\"en\""
        if let theme = parts.activeTheme {
            htmlTag.append(" data-theme=\"\(theme.attributeEscaped)\"")
        }
        htmlTag.append(">")
        var html = "<!DOCTYPE html>\n\(htmlTag)\n<head>\n"
        html.append("<meta charset=\"utf-8\">\n")
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")

        if let title = parts.title {
            html.append("<title>\(title.htmlEscaped)</title>\n")
        }

        if let description = parts.description, !description.isEmpty {
            html.append("<meta name=\"description\" content=\"\(description.attributeEscaped)\">\n")
        }

        if !parts.keywords.isEmpty {
            let escaped = parts.keywords.map(\.attributeEscaped).joined(separator: ", ")
            html.append("<meta name=\"keywords\" content=\"\(escaped)\">\n")
        }

        if parts.externalAssets {
            html.append("<link rel=\"stylesheet\" href=\"/as-global.css\">\n")
            if !parts.componentCSS.isEmpty {
                html.append("<link rel=\"stylesheet\" href=\"/as-group-0.css\">\n")
            }
        } else {
            if !parts.themeCSS.isEmpty {
                html.append("<style>\n\(parts.themeCSS)</style>\n")
            }
            if !parts.componentCSS.isEmpty {
                html.append("<style>\n\(parts.componentCSS)</style>\n")
            }
        }

        for payload in parts.structuredData {
            html.append("<script type=\"application/ld+json\">\(payload)</script>\n")
        }

        html.append("</head>\n<body>\n")
        html.append(parts.bodyHTML)
        html.append("\n")

        if parts.externalAssets {
            let hasReactiveScripts = parts.scripts.contains { $0.contains("Score.state") || $0.contains("Score.computed") }
            if hasReactiveScripts {
                html.append("<script src=\"/signal-polyfill.js\"></script>\n")
                html.append("<script src=\"/score-runtime.js\"></script>\n")
                html.append("<script src=\"/as-interactivity.js\" defer></script>\n")
            }
        } else {
            for script in parts.scripts {
                html.append(script)
                html.append("\n")
            }
        }

        html.append("</body>\n</html>\n")
        return html
    }
}
