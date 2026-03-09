import Foundation

/// Loads content files from disk with optional front matter extraction.
///
/// `ContentLoader` reads Markdown and other text-based content files from a
/// directory, parses their front matter, and provides the raw body for further
/// processing. It is the low-level building block used by ``ContentCollection``
/// to index content at build time.
///
/// ```swift
/// let loader = ContentLoader(directory: "/path/to/content")
/// let items = try loader.loadAll()
/// ```
public struct ContentLoader: Sendable {

    /// The directory from which content files are loaded.
    public let directory: String

    /// The file extension filter. Only files matching this extension are loaded.
    public let fileExtension: String

    /// Creates a content loader for the given directory.
    ///
    /// Both absolute and relative paths are accepted. Relative paths are
    /// resolved against the current working directory.
    ///
    /// - Parameters:
    ///   - directory: The path to the content directory.
    ///   - fileExtension: The file extension to filter on. Defaults to `"md"`.
    public init(directory: String, fileExtension: String = "md") {
        if directory.hasPrefix("/") {
            self.directory = directory
        } else {
            self.directory = FileManager.default.currentDirectoryPath + "/" + directory
        }
        self.fileExtension = fileExtension
    }

    /// A single loaded content file with its metadata and body.
    public struct LoadedContent: Sendable {

        /// The filename without extension, suitable for use as a URL slug.
        public let slug: String

        /// The original filename including extension.
        public let filename: String

        /// The parsed front matter, or `nil` if the file has no front matter block.
        public let frontMatter: FrontMatter?

        /// The content body with front matter stripped.
        public let body: String
    }

    /// Loads a single file at the given path.
    ///
    /// Both absolute and relative paths are accepted. Relative paths are
    /// resolved against the current working directory.
    ///
    /// - Parameter path: The file path.
    /// - Returns: A ``LoadedContent`` value with parsed front matter and body.
    /// - Throws: An error if the file cannot be read.
    public func load(path: String) throws -> LoadedContent {
        let resolved = path.hasPrefix("/") ? path : FileManager.default.currentDirectoryPath + "/" + path
        let url = URL(fileURLWithPath: resolved)
        let content = try String(contentsOf: url, encoding: .utf8)
        let filename = url.lastPathComponent
        let slug = url.deletingPathExtension().lastPathComponent
        let frontMatter = FrontMatter.parse(from: content)
        let body = FrontMatter.body(from: content)
        return LoadedContent(slug: slug, filename: filename, frontMatter: frontMatter, body: body)
    }

    /// Loads all matching content files from the configured directory.
    ///
    /// Files are filtered by ``fileExtension`` and sorted alphabetically by
    /// filename.
    ///
    /// - Returns: An array of ``LoadedContent`` values.
    /// - Throws: An error if the directory cannot be read or any file fails to load.
    public func loadAll() throws -> [LoadedContent] {
        let fm = FileManager.default
        let dirURL = URL(fileURLWithPath: directory)

        guard fm.fileExists(atPath: directory) else {
            return []
        }

        let files = try fm.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let matching =
            files
            .filter { $0.pathExtension == fileExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try matching.map { url in
            try load(path: url.path)
        }
    }
}
