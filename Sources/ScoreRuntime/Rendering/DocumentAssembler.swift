import ScoreHTML

/// Assembles a complete HTML document from rendered parts.
public struct DocumentAssembler: Sendable {

    /// The components of an HTML document.
    public struct Parts: Sendable {
        /// The document `<title>`.
        public var title: String?
        /// The meta description.
        public var description: String?
        /// The meta keywords.
        public var keywords: [String]?
        /// The rendered body HTML.
        public var bodyHTML: String?
        /// External CSS file paths to link in `<head>`.
        public var cssLinks: [String]
        /// Structured data payloads (JSON-LD).
        public var structuredData: [String]?
        /// Script tags to append before `</body>`.
        public var scripts: [String]?
        /// The active theme name for `data-theme` on `<html>`.
        public var activeTheme: String?
        /// The canonical URL for this page.
        public var canonicalURL: String?
        /// The site name for Open Graph tags.
        public var ogSiteName: String?
        /// Extra `<link>` tags for the `<head>` (e.g. font preconnects).
        public var headLinks: [String]
        /// Named theme variant keys from the active theme.
        ///
        /// When non-empty, the assembler emits a blocking `<script>` in the
        /// `<head>` that restores the user's persisted theme choice from
        /// `localStorage` before first paint, preventing a flash of
        /// unstyled content (FOUC).
        public var themeNames: [String]
        /// External JavaScript file paths to link before `</body>`.
        public var scriptLinks: [String]

        /// Creates document parts.
        public init(
            title: String? = nil,
            description: String? = nil,
            keywords: [String]? = nil,
            bodyHTML: String? = nil,
            cssLinks: [String] = [],
            structuredData: [String]? = nil,
            scripts: [String]? = nil,
            activeTheme: String? = nil,
            canonicalURL: String? = nil,
            ogSiteName: String? = nil,
            headLinks: [String] = [],
            themeNames: [String] = [],
            scriptLinks: [String] = []
        ) {
            self.title = title
            self.description = description
            self.keywords = keywords
            self.bodyHTML = bodyHTML
            self.cssLinks = cssLinks
            self.structuredData = structuredData
            self.scripts = scripts
            self.activeTheme = activeTheme
            self.canonicalURL = canonicalURL
            self.ogSiteName = ogSiteName
            self.headLinks = headLinks
            self.themeNames = themeNames
            self.scriptLinks = scriptLinks
        }
    }

    private init() {}

    /// Composes a document title from optional page and site components.
    public static func composeTitle(
        page: String?,
        separator: String,
        site: String?
    ) -> String? {
        switch (page, site) {
        case (let p?, let s?): return "\(p)\(separator)\(s)"
        case (let p?, nil): return p
        case (nil, let s?): return s
        case (nil, nil): return nil
        }
    }

    /// Assembles a complete HTML document string from parts.
    public static func assemble(_ parts: Parts) -> String {
        var html = "<!DOCTYPE html>\n"

        // <html>
        if let theme = parts.activeTheme {
            html.append("<html lang=\"en\" data-theme=\"\(theme.htmlEscaped)\">\n")
        } else {
            html.append("<html lang=\"en\">\n")
        }

        // <head>
        html.append("<head>\n")
        html.append("<meta charset=\"utf-8\">\n")
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")

        if let title = parts.title {
            html.append("<title>\(title.htmlEscaped)</title>\n")
        }
        if let description = parts.description {
            html.append("<meta name=\"description\" content=\"\(description.attributeEscaped)\">\n")
        }
        if let keywords = parts.keywords, !keywords.isEmpty {
            let escaped = keywords.map(\.htmlEscaped).joined(separator: ", ")
            html.append("<meta name=\"keywords\" content=\"\(escaped)\">\n")
        }
        if let canonical = parts.canonicalURL {
            html.append("<link rel=\"canonical\" href=\"\(canonical.attributeEscaped)\">\n")
        }

        // Open Graph tags
        if let title = parts.title {
            html.append("<meta property=\"og:title\" content=\"\(title.attributeEscaped)\">\n")
        }
        if let description = parts.description {
            html.append("<meta property=\"og:description\" content=\"\(description.attributeEscaped)\">\n")
        }
        if let siteName = parts.ogSiteName {
            html.append("<meta property=\"og:site_name\" content=\"\(siteName.attributeEscaped)\">\n")
        }
        html.append("<meta property=\"og:type\" content=\"website\">\n")
        if let canonical = parts.canonicalURL {
            html.append("<meta property=\"og:url\" content=\"\(canonical.attributeEscaped)\">\n")
        }

        for link in parts.headLinks {
            html.append("\(link)\n")
        }
        for link in parts.cssLinks {
            html.append("<link rel=\"stylesheet\" href=\"\(link)\">\n")
        }
        if let structuredData = parts.structuredData {
            for data in structuredData {
                html.append("<script type=\"application/ld+json\">\(data)</script>\n")
            }
        }
        if !parts.themeNames.isEmpty {
            html.append(themePersistenceScript(names: parts.themeNames))
        }
        html.append("</head>\n")

        // <body>
        html.append("<body>\n")
        if let bodyHTML = parts.bodyHTML {
            html.append(bodyHTML)
        }
        html.append("\n")

        for link in parts.scriptLinks {
            html.append("<script src=\"\(link)\"></script>\n")
        }
        if let scripts = parts.scripts {
            for script in scripts {
                html.append(script)
                html.append("\n")
            }
        }

        html.append("</body>\n</html>\n")
        return html
    }

    /// Emits a blocking `<script>` that restores a persisted theme from
    /// `localStorage` before first paint, preventing FOUC.
    ///
    /// The script checks for a `"as-theme"` key in `localStorage` whose
    /// value matches one of the given theme names, and sets
    /// `data-theme` on `<html>` if found.
    private static func themePersistenceScript(names: [String]) -> String {
        let allowed = names.map { "\"\($0.htmlEscaped)\"" }.joined(separator: ",")
        return
            "<script>!function(){var t=localStorage.getItem(\"as-theme\");if(t&&[\(allowed)].indexOf(t)!==-1)document.documentElement.setAttribute(\"data-theme\",t)}()</script>\n"
    }
}
