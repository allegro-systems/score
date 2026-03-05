/// Application and page-level document metadata.
///
/// `Metadata` is a concrete value type used for both application-wide defaults
/// and page-level overrides. All fields are optional so pages only set what
/// they need — unset fields inherit the application value at render time.
///
/// ### Application-level
///
/// ```swift
/// struct MyApp: Application {
///     var metadata: Metadata? {
///         Metadata(site: "Acme", description: "Ship faster with Acme.")
///     }
/// }
/// ```
///
/// ### Page-level override
///
/// ```swift
/// struct AboutPage: Page {
///     static let path = "/about"
///     var metadata: Metadata? {
///         Metadata(title: "About", description: "Learn about Acme.")
///     }
/// }
/// ```
///
/// At render time, page values take precedence over application values.
public struct Metadata: Sendable {

    /// The optional site name used in title composition.
    public var site: String?

    /// The optional document title.
    public var title: String?

    /// The separator used when composing page and site titles.
    public var titleSeparator: String?

    /// The optional document description.
    public var description: String?

    /// The keyword list for meta tags.
    public var keywords: [String]?

    /// Structured data payloads represented as JSON strings.
    public var structuredData: [String]?

    /// Creates a metadata value.
    public init(
        site: String? = nil,
        title: String? = nil,
        titleSeparator: String? = nil,
        description: String? = nil,
        keywords: [String]? = nil,
        structuredData: [String]? = nil
    ) {
        self.site = site
        self.title = title
        self.titleSeparator = titleSeparator
        self.description = description
        self.keywords = keywords
        self.structuredData = structuredData
    }
}
