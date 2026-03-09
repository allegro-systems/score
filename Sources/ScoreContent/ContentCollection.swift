import Foundation

/// An indexed collection of content items for blogs, documentation sites,
/// and other structured content.
///
/// `ContentCollection` loads content files from a directory, indexes them by
/// slug (derived from filename), and provides lookup and filtering operations.
/// Each item carries its parsed ``FrontMatter`` and raw body text, ready for
/// conversion to Score nodes via ``MarkdownConverter``.
///
/// ```swift
/// let posts = try ContentCollection(directory: "content/posts")
/// let latest = posts.sorted(by: "date", ascending: false)
/// let post = posts.item(slug: "hello-world")
/// ```
public struct ContentCollection: Sendable {

    /// A single content item in the collection.
    public struct Item: Sendable {

        /// A URL-safe identifier derived from the filename (without extension).
        public let slug: String

        /// The original filename including extension.
        public let filename: String

        /// The parsed front matter metadata, or `nil` if absent.
        public let frontMatter: FrontMatter?

        /// The content body with front matter stripped.
        public let body: String

        /// Creates a content item.
        public init(slug: String, filename: String, frontMatter: FrontMatter?, body: String) {
            self.slug = slug
            self.filename = filename
            self.frontMatter = frontMatter
            self.body = body
        }
    }

    /// All items in the collection, in the order they were loaded.
    public let items: [Item]

    /// A dictionary mapping slugs to items for O(1) lookup.
    private let index: [String: Item]

    /// Creates a content collection from an array of items.
    ///
    /// - Parameter items: The content items to include.
    public init(items: [Item]) {
        self.items = items
        var indexMap: [String: Item] = [:]
        for item in items {
            indexMap[item.slug] = item
        }
        self.index = indexMap
    }

    /// Creates a content collection by loading all matching files from a
    /// directory.
    ///
    /// Both absolute and relative paths are accepted. Relative paths are
    /// resolved against the current working directory.
    ///
    /// - Parameters:
    ///   - directory: The path to the content directory.
    ///   - fileExtension: The file extension filter. Defaults to `"md"`.
    /// - Throws: An error if the directory cannot be read.
    public init(directory: String, fileExtension: String = "md") throws {
        let loader = ContentLoader(directory: directory, fileExtension: fileExtension)
        let loaded = try loader.loadAll()
        let mapped = loaded.map { content in
            Item(
                slug: content.slug,
                filename: content.filename,
                frontMatter: content.frontMatter,
                body: content.body
            )
        }
        self.init(items: mapped)
    }

    /// Creates a content collection by loading all matching files from a
    /// directory, returning an empty collection on failure.
    ///
    /// Both absolute and relative paths are accepted. Relative paths are
    /// resolved against the current working directory.
    ///
    /// - Parameters:
    ///   - directory: The path to the content directory.
    ///   - fileExtension: The file extension filter. Defaults to `"md"`.
    public init(loading directory: String, fileExtension: String = "md") {
        if let collection = try? ContentCollection(directory: directory, fileExtension: fileExtension) {
            self = collection
        } else {
            self.init(items: [])
        }
    }

    /// The number of items in the collection.
    public var count: Int {
        items.count
    }

    /// Whether the collection contains no items.
    public var isEmpty: Bool {
        items.isEmpty
    }

    /// Looks up a content item by its slug.
    ///
    /// - Parameter slug: The slug to search for.
    /// - Returns: The matching ``Item``, or `nil` if not found.
    public func item(slug: String) -> Item? {
        index[slug]
    }

    /// Returns items filtered by a front matter predicate.
    ///
    /// - Parameter predicate: A closure that receives the ``FrontMatter``
    ///   (if present) and returns `true` for items to include.
    /// - Returns: A new ``ContentCollection`` containing only matching items.
    public func filter(_ predicate: (FrontMatter?) -> Bool) -> ContentCollection {
        ContentCollection(items: items.filter { predicate($0.frontMatter) })
    }

    /// Returns items sorted by a front matter key using string comparison.
    ///
    /// Items without the specified key are placed at the end.
    ///
    /// - Parameters:
    ///   - key: The front matter key to sort by.
    ///   - ascending: Whether to sort in ascending order. Defaults to `true`.
    /// - Returns: A new ``ContentCollection`` with items in the requested order.
    public func sorted(by key: String, ascending: Bool = true) -> ContentCollection {
        let sorted = items.sorted { a, b in
            let aVal = a.frontMatter?.string(key) ?? ""
            let bVal = b.frontMatter?.string(key) ?? ""
            return ascending ? aVal < bVal : aVal > bVal
        }
        return ContentCollection(items: sorted)
    }

    /// Returns all unique values for a given front matter key across the
    /// collection.
    ///
    /// - Parameter key: The front matter key to extract values from.
    /// - Returns: An array of unique string values, in the order first
    ///   encountered.
    public func uniqueValues(for key: String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in items {
            if let value = item.frontMatter?.string(key), seen.insert(value).inserted {
                result.append(value)
            }
        }
        return result
    }

    /// Returns all unique tag values for a given front matter key across the
    /// collection, splitting comma-separated values.
    ///
    /// - Parameter key: The front matter key to extract tags from.
    /// - Returns: An array of unique tag strings, in the order first encountered.
    public func uniqueTags(for key: String) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for item in items {
            let tags = item.frontMatter?.list(key) ?? []
            for tag in tags {
                if seen.insert(tag).inserted {
                    result.append(tag)
                }
            }
        }
        return result
    }
}
