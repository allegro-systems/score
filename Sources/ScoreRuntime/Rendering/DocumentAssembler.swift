import ScoreHTML

/// Assembles a complete HTML document from rendered parts.
public struct DocumentAssembler: Sendable {

    /// The components of an HTML document.
    public struct Parts: Sendable {
        /// SEO and social metadata for the document.
        public var seo: SEOMetadata
        /// The rendered body HTML.
        public var bodyHTML: String?
        /// CSS and theme configuration for the document.
        public var css: CSSConfig
        /// JavaScript configuration for the document.
        public var scripts: ScriptConfig
        /// The locale for the `lang` attribute on `<html>`. Defaults to `"en"`.
        public var locale: String

        /// SEO metadata, Open Graph tags, and structured data.
        public struct SEOMetadata: Sendable {
            /// The document `<title>`.
            public var title: String?
            /// The meta description.
            public var description: String?
            /// The meta keywords.
            public var keywords: [String]?
            /// The canonical URL for this page.
            public var canonicalURL: String?
            /// The site name for Open Graph tags.
            public var ogSiteName: String?
            /// Structured data payloads (JSON-LD).
            public var structuredData: [String]?

            public init(
                title: String? = nil,
                description: String? = nil,
                keywords: [String]? = nil,
                canonicalURL: String? = nil,
                ogSiteName: String? = nil,
                structuredData: [String]? = nil
            ) {
                self.title = title
                self.description = description
                self.keywords = keywords
                self.canonicalURL = canonicalURL
                self.ogSiteName = ogSiteName
                self.structuredData = structuredData
            }
        }

        /// CSS stylesheets, theme, and visual configuration.
        public struct CSSConfig: Sendable {
            /// External CSS file paths to link in `<head>`.
            public var cssLinks: [String]
            /// Extra `<link>` tags for the `<head>` (e.g. font preconnects).
            public var headLinks: [String]
            /// The active theme name for `data-theme` on `<html>`.
            public var activeTheme: String?
            /// Named theme variant keys from the active theme.
            ///
            /// When non-empty, the assembler emits a blocking `<script>` in the
            /// `<head>` that restores the user's persisted theme choice from
            /// `localStorage` before first paint, preventing a flash of
            /// unstyled content (FOUC).
            public var themeNames: [String]
            /// Whether to emit a `<meta name="view-transition">` tag for the
            /// View Transitions API. Defaults to `false`.
            public var viewTransitions: Bool

            public init(
                cssLinks: [String] = [],
                headLinks: [String] = [],
                activeTheme: String? = nil,
                themeNames: [String] = [],
                viewTransitions: Bool = false
            ) {
                self.cssLinks = cssLinks
                self.headLinks = headLinks
                self.activeTheme = activeTheme
                self.themeNames = themeNames
                self.viewTransitions = viewTransitions
            }
        }

        /// JavaScript configuration: inline scripts, external links, and pre-scripts.
        public struct ScriptConfig: Sendable {
            /// Script tags to append before `</body>`.
            public var inline: [String]?
            /// External JavaScript file paths to link before `</body>`.
            public var scriptLinks: [String]
            /// Inline scripts emitted before external script links (e.g., dev tools metadata).
            public var preScripts: [String]

            public init(
                inline: [String]? = nil,
                scriptLinks: [String] = [],
                preScripts: [String] = []
            ) {
                self.inline = inline
                self.scriptLinks = scriptLinks
                self.preScripts = preScripts
            }
        }

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
            scriptLinks: [String] = [],
            preScripts: [String] = [],
            viewTransitions: Bool = false,
            locale: String = "en"
        ) {
            self.seo = SEOMetadata(
                title: title,
                description: description,
                keywords: keywords,
                canonicalURL: canonicalURL,
                ogSiteName: ogSiteName,
                structuredData: structuredData
            )
            self.bodyHTML = bodyHTML
            self.css = CSSConfig(
                cssLinks: cssLinks,
                headLinks: headLinks,
                activeTheme: activeTheme,
                themeNames: themeNames,
                viewTransitions: viewTransitions
            )
            self.scripts = ScriptConfig(
                inline: scripts,
                scriptLinks: scriptLinks,
                preScripts: preScripts
            )
            self.locale = locale
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
        let lang = parts.locale.htmlEscaped
        if let theme = parts.css.activeTheme {
            html.append("<html lang=\"\(lang)\" data-theme=\"\(theme.htmlEscaped)\">\n")
        } else {
            html.append("<html lang=\"\(lang)\">\n")
        }

        // <head>
        html.append("<head>\n")
        html.append("<meta charset=\"utf-8\">\n")
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")
        if parts.css.viewTransitions {
            html.append("<meta name=\"view-transition\" content=\"same-origin\">\n")
        }

        if let title = parts.seo.title {
            html.append("<title>\(title.htmlEscaped)</title>\n")
        }
        if let description = parts.seo.description {
            html.append("<meta name=\"description\" content=\"\(description.attributeEscaped)\">\n")
        }
        if let keywords = parts.seo.keywords, !keywords.isEmpty {
            let escaped = keywords.map(\.htmlEscaped).joined(separator: ", ")
            html.append("<meta name=\"keywords\" content=\"\(escaped)\">\n")
        }
        if let canonical = parts.seo.canonicalURL {
            html.append("<link rel=\"canonical\" href=\"\(canonical.attributeEscaped)\">\n")
        }

        // Open Graph tags
        if let title = parts.seo.title {
            html.append("<meta property=\"og:title\" content=\"\(title.attributeEscaped)\">\n")
        }
        if let description = parts.seo.description {
            html.append("<meta property=\"og:description\" content=\"\(description.attributeEscaped)\">\n")
        }
        if let siteName = parts.seo.ogSiteName {
            html.append("<meta property=\"og:site_name\" content=\"\(siteName.attributeEscaped)\">\n")
        }
        html.append("<meta property=\"og:type\" content=\"website\">\n")
        if let canonical = parts.seo.canonicalURL {
            html.append("<meta property=\"og:url\" content=\"\(canonical.attributeEscaped)\">\n")
        }

        for link in parts.css.headLinks {
            html.append("\(link)\n")
        }
        for link in parts.css.cssLinks {
            html.append("<link rel=\"stylesheet\" href=\"\(link)\">\n")
        }
        if let structuredData = parts.seo.structuredData {
            for data in structuredData {
                html.append("<script type=\"application/ld+json\">\(data)</script>\n")
            }
        }
        if !parts.css.themeNames.isEmpty {
            html.append(themePersistenceScript(names: parts.css.themeNames))
        }
        html.append("</head>\n")

        // <body>
        html.append("<body>\n")
        if let bodyHTML = parts.bodyHTML {
            html.append(bodyHTML)
        }
        html.append("\n")

        for script in parts.scripts.preScripts {
            html.append(script)
            html.append("\n")
        }
        for link in parts.scripts.scriptLinks {
            html.append("<script src=\"\(link)\"></script>\n")
        }
        if let inlineScripts = parts.scripts.inline {
            for script in inlineScripts {
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
        var effectiveNames = names
        if names.contains("dark") && !names.contains("light") {
            effectiveNames.append("light")
        }
        let allowed = effectiveNames.map { "\"\($0.htmlEscaped)\"" }.joined(separator: ",")
        return
            "<script>!function(){var t=localStorage.getItem(\"as-theme\");if(t===\"true\")t=\"dark\";if(t===\"false\")t=\"light\";if(t&&[\(allowed)].indexOf(t)!==-1){document.documentElement.setAttribute(\"data-theme\",t)}}()</script>\n"
    }
}
