import Foundation

/// A mapping from logical asset paths to fingerprinted URLs.
///
/// `AssetManifest` is the central lookup table produced by the asset pipeline.
/// Templates and helpers use ``resolve(_:)`` to translate a human-readable
/// path like `"css/main.css"` into its fingerprinted counterpart
/// `"css/main-a1b2c3d4.css"`, enabling immutable caching at the CDN layer.
public struct AssetManifest: Sendable {

    /// The entries mapping original paths to fingerprinted paths.
    ///
    /// Keys are the logical (original) asset paths relative to the asset
    /// directory root, and values are the corresponding fingerprinted paths.
    public let entries: [String: String]

    /// Creates a manifest with the given entries.
    ///
    /// - Parameter entries: A dictionary mapping logical paths to fingerprinted
    ///   paths. Defaults to an empty dictionary.
    public init(entries: [String: String] = [:]) {
        self.entries = entries
    }

    /// Makes a manifest by scanning a directory recursively.
    ///
    /// Every regular file found under `directory` is read, fingerprinted, and
    /// added to the manifest. The logical path stored as the key is the file's
    /// path relative to `directory`.
    ///
    /// - Parameter directory: The root directory to scan.
    /// - Returns: A populated ``AssetManifest``.
    /// - Throws: An error if the directory cannot be enumerated or a file
    ///   cannot be read.
    public static func make(from directory: String) throws -> AssetManifest {
        let fileManager = FileManager.default
        let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)

        guard
            let enumerator = fileManager.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return AssetManifest()
        }

        var entries: [String: String] = [:]

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }

            let relativePath = fileURL.path.replacingOccurrences(
                of: directoryURL.path + "/",
                with: ""
            )

            let data = try Data(contentsOf: fileURL)
            let fingerprintedName = AssetFingerprint.fingerprintedName(
                original: fileURL.lastPathComponent,
                data: data
            )

            let directory = (relativePath as NSString).deletingLastPathComponent
            let fingerprintedPath: String
            if directory.isEmpty || directory == "." {
                fingerprintedPath = fingerprintedName
            } else {
                fingerprintedPath = "\(directory)/\(fingerprintedName)"
            }

            entries[relativePath] = fingerprintedPath
        }

        return AssetManifest(entries: entries)
    }

    /// Resolves a logical asset path to its fingerprinted URL.
    ///
    /// If the manifest contains a fingerprinted version of the given path,
    /// that version is returned. Otherwise the original path is returned
    /// unchanged, allowing graceful degradation when an asset has not been
    /// processed.
    ///
    /// - Parameter path: The logical asset path (e.g. `"css/main.css"`).
    /// - Returns: The fingerprinted path if available, otherwise the original.
    public func resolve(_ path: String) -> String {
        entries[path] ?? path
    }
}
