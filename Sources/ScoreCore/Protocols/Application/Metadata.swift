/// A protocol defining document metadata for application and page use.
///
/// `Metadata` captures optional document-level fields that renderers
/// use to emit `<title>`, `<meta>`, and structured data tags. All
/// properties default to `nil` so conforming types only declare what
/// they need — unset fields inherit the application value at render time.
///
/// ### Application-level
///
/// ```swift
/// struct MyApp: Application {
///     var metadata: (any Metadata)? {
///         SiteMetadata(site: "Acme", description: "Ship faster with Acme.")
///     }
/// }
/// ```
///
/// ### Page-level override
///
/// ```swift
/// struct AboutPage: Page {
///     static let path = "/about"
///     var metadata: (any Metadata)? {
///         SiteMetadata(title: "About", description: "Learn about Acme.")
///     }
/// }
/// ```
///
/// At render time, page values take precedence over application values.
public protocol Metadata: Sendable {

    /// The optional site name used in title composition.
    var site: String? { get }

    /// The optional document title.
    var title: String? { get }

    /// The separator used when composing page and site titles.
    var titleSeparator: String? { get }

    /// The optional document description.
    var description: String? { get }

    /// The keyword list for meta tags.
    var keywords: [String]? { get }

    /// Structured data payloads represented as JSON strings.
    var structuredData: [String]? { get }
}

extension Metadata {
    public var site: String? { nil }
    public var title: String? { nil }
    public var titleSeparator: String? { nil }
    public var description: String? { nil }
    public var keywords: [String]? { nil }
    public var structuredData: [String]? { nil }
}

/// A concrete metadata value with all standard document metadata fields.
public struct SiteMetadata: Metadata {

    public var site: String?
    public var title: String?
    public var titleSeparator: String?
    public var description: String?
    public var keywords: [String]?
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
