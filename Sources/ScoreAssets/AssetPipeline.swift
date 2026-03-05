import Foundation

/// Orchestrates the full asset processing pipeline: fingerprint, optimize,
/// and manifest.
///
/// `AssetPipeline` scans a source directory for assets, computes
/// content-based fingerprints, applies compression to compressible types,
/// writes the processed files to an output directory, and returns the
/// resulting ``AssetManifest`` for use by templates and route handlers.
///
/// ```swift
/// let pipeline = AssetPipeline(
///     sourceDirectory: "assets",
///     outputDirectory: "public/assets"
/// )
/// let manifest = try pipeline.process()
/// let url = manifest.resolve("css/main.css")
/// // "css/main-a1b2c3d4.css"
/// ```
public struct AssetPipeline: Sendable {

    /// The directory containing unprocessed source assets.
    public let sourceDirectory: String

    /// The directory where fingerprinted and optimized assets are written.
    public let outputDirectory: String

    /// Creates a pipeline with the given source and output directories.
    ///
    /// - Parameters:
    ///   - sourceDirectory: The path to the directory containing source assets.
    ///   - outputDirectory: The path to the directory where processed assets
    ///     will be written.
    public init(sourceDirectory: String, outputDirectory: String) {
        self.sourceDirectory = sourceDirectory
        self.outputDirectory = outputDirectory
    }

    /// Processes all assets in the source directory.
    ///
    /// For each file found recursively under ``sourceDirectory``:
    /// 1. The content is read and fingerprinted.
    /// 2. If the asset type is compressible, gzip compression is applied.
    /// 3. The processed file is written to ``outputDirectory`` using the
    ///    fingerprinted filename.
    /// 4. An entry is recorded in the manifest.
    ///
    /// The output directory and any necessary subdirectories are created
    /// automatically if they do not exist.
    ///
    /// - Returns: The generated ``AssetManifest`` mapping logical paths to
    ///   fingerprinted paths.
    /// - Throws: An error if the source directory cannot be enumerated, a
    ///   file cannot be read, or the output cannot be written.
    public func process() throws -> AssetManifest {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: sourceDirectory, isDirectory: true)
        let outputURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)

        try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

        guard
            let enumerator = fileManager.enumerator(
                at: sourceURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return AssetManifest()
        }

        let optimizer = AssetOptimizer()
        var entries: [String: String] = [:]

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }

            let relativePath = fileURL.path.replacingOccurrences(
                of: sourceURL.path + "/",
                with: ""
            )

            let data = try Data(contentsOf: fileURL)
            let fingerprintedName = AssetFingerprint.fingerprintedName(
                original: fileURL.lastPathComponent,
                data: data
            )

            let relativeDir = (relativePath as NSString).deletingLastPathComponent
            let fingerprintedPath: String
            if relativeDir.isEmpty || relativeDir == "." {
                fingerprintedPath = fingerprintedName
            } else {
                fingerprintedPath = "\(relativeDir)/\(fingerprintedName)"
            }

            let assetType = AssetType.detect(from: fileURL.lastPathComponent)
            let outputData: Data
            if let assetType {
                let optimized = optimizer.optimize(data, type: assetType)
                outputData = optimized.data
            } else {
                outputData = data
            }

            let outputFileURL: URL
            if relativeDir.isEmpty || relativeDir == "." {
                outputFileURL = outputURL.appendingPathComponent(fingerprintedName)
            } else {
                let subdir = outputURL.appendingPathComponent(relativeDir)
                try fileManager.createDirectory(at: subdir, withIntermediateDirectories: true)
                outputFileURL = subdir.appendingPathComponent(fingerprintedName)
            }

            try outputData.write(to: outputFileURL)
            entries[relativePath] = fingerprintedPath
        }

        return AssetManifest(entries: entries)
    }
}
