import ScoreHTML

/// Assembles a complete HTML document from rendered parts.
public struct DocumentAssembler: Sendable {

    /// The components of an HTML document.
    public struct Parts: Sendable {
        public var title: String?
        public var description: String?
        public var keywords: [String]?
        public var bodyHTML: String?
        public var themeCSS: String?
        public var componentCSS: String?
        public var structuredData: [String]?
        public var scripts: [String]?
        public var activeTheme: String?

        public init(
            title: String? = nil,
            description: String? = nil,
            keywords: [String]? = nil,
            bodyHTML: String? = nil,
            themeCSS: String? = nil,
            componentCSS: String? = nil,
            structuredData: [String]? = nil,
            scripts: [String]? = nil,
            activeTheme: String? = nil
        ) {
            self.title = title
            self.description = description
            self.keywords = keywords
            self.bodyHTML = bodyHTML
            self.themeCSS = themeCSS
            self.componentCSS = componentCSS
            self.structuredData = structuredData
            self.scripts = scripts
            self.activeTheme = activeTheme
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
        case let (p?, s?): return "\(p)\(separator)\(s)"
        case let (p?, nil): return p
        case let (nil, s?): return s
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
        if let themeCSS = parts.themeCSS {
            html.append("<style>\n\(themeCSS)</style>\n")
        }
        if let componentCSS = parts.componentCSS, !componentCSS.isEmpty {
            html.append("<style>\n\(componentCSS)</style>\n")
        }
        if let structuredData = parts.structuredData {
            for data in structuredData {
                html.append("<script type=\"application/ld+json\">\(data)</script>\n")
            }
        }
        html.append("</head>\n")

        // <body>
        html.append("<body>\n")
        if let bodyHTML = parts.bodyHTML {
            html.append(bodyHTML)
        }
        html.append("\n")

        if let scripts = parts.scripts {
            for script in scripts {
                html.append(script)
                html.append("\n")
            }
        }

        html.append("</body>\n</html>\n")
        return html
    }
}
