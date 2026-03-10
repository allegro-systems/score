import ScoreCore

/// A page whose instances are generated from a content directory.
///
/// Instead of declaring individual `Page` structs for every markdown file,
/// define a single `ContentPage` type with a `content` directory and `prefix`.
/// The framework generates one page per content item, injecting the item
/// via the `item` property.
///
/// ```swift
/// struct DocumentationPages: ContentPage {
///     static let content = "Content/docs/score"
///     static let prefix = "/docs/score"
///
///     var item: ContentCollection.Item
///
///     var body: some Node {
///         DocsLayout(sidebar: { DocsSidebar() }) {
///             MarkdownNode(item.body)
///         }
///     }
/// }
/// ```
///
/// Then register it in your application:
///
/// ```swift
/// @PageBuilder
/// var pages: [any Page] {
///     HomePage()
///     DocumentationPages()
///     NotFoundPage()
/// }
/// ```
public protocol ContentPage: PageProvider, Sendable {
    associatedtype Body: Node

    /// The path to the content directory (relative or absolute).
    static var content: String { get }

    /// The URL path prefix. Each item's slug is appended to this.
    /// An item with slug `"index"` maps to the prefix itself.
    static var prefix: String { get }

    /// The current content item, injected by the framework.
    var item: ContentCollection.Item { get }

    /// An optional page-level metadata override.
    var metadata: (any Metadata)? { get }

    /// The page body, rendered once per content item.
    @NodeBuilder
    var body: Body { get }

    /// Creates an instance with the given content item.
    init(item: ContentCollection.Item)
}

extension ContentPage {

    /// Default metadata returns `nil`, inheriting application-level metadata.
    public var metadata: (any Metadata)? { nil }

    /// Generates one page per content item in the directory.
    public var pages: [any Page] {
        let collection = ContentCollection(loading: Self.content)
        return collection.items.map { contentItem in
            let pagePath =
                contentItem.slug == "index"
                ? Self.prefix
                : "\(Self.prefix)/\(contentItem.slug)"
            let instance = Self(item: contentItem)
            return ContentItemPage(pagePath: pagePath, body: instance.body, metadata: instance.metadata)
        }
    }

    /// Convenience initializer for use in `@PageBuilder`.
    /// Creates a provider instance (the `item` is unused for the provider itself).
    public init() {
        let collection = ContentCollection(loading: Self.content)
        self.init(item: collection.items.first ?? ContentCollection.Item(slug: "", filename: "", frontMatter: nil, body: ""))
    }
}

/// A type-erased page backed by a content item.
struct ContentItemPage<Body: Node>: Page, @unchecked Sendable {

    let pagePath: String
    let storedBody: Body
    let storedMetadata: (any Metadata)?

    static var path: String { "/_content" }

    var path: String { pagePath }

    var metadata: (any Metadata)? { storedMetadata }

    var body: some Node { storedBody }

    init(pagePath: String, body: Body, metadata: (any Metadata)? = nil) {
        self.pagePath = pagePath
        self.storedBody = body
        self.storedMetadata = metadata
    }
}
