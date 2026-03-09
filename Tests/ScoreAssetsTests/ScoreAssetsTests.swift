import Foundation
import Testing

@testable import ScoreAssets

@Test func fingerprintIsDeterministic() {
    let data = Data("hello world".utf8)
    let first = AssetFingerprint.hash(data)
    let second = AssetFingerprint.hash(data)
    #expect(first == second)
}

@Test func fingerprintDiffersForDifferentData() {
    let a = AssetFingerprint.hash(Data("hello".utf8))
    let b = AssetFingerprint.hash(Data("world".utf8))
    #expect(a != b)
}

@Test func fingerprintIsEightHexCharacters() {
    let hash = AssetFingerprint.hash(Data("test".utf8))
    #expect(hash.count == 8)
    #expect(hash.allSatisfy { $0.isHexDigit })
}

@Test func fingerprintedNameInsertsHashBeforeExtension() {
    let data = Data("body { color: red; }".utf8)
    let name = AssetFingerprint.fingerprintedName(original: "main.css", data: data)
    #expect(name.hasPrefix("main-"))
    #expect(name.hasSuffix(".css"))
    #expect(name.count == "main-.css".count + 8)
}

@Test func fingerprintedNameHandlesNoExtension() {
    let data = Data("content".utf8)
    let name = AssetFingerprint.fingerprintedName(original: "LICENSE", data: data)
    #expect(name.hasPrefix("LICENSE-"))
    #expect(name.count == "LICENSE-".count + 8)
}

@Test func manifestResolveReturnsFingerprinted() {
    let manifest = AssetManifest(entries: [
        "css/main.css": "css/main-abcd1234.css"
    ])
    #expect(manifest.resolve("css/main.css") == "css/main-abcd1234.css")
}

@Test func manifestResolveFallsBackToOriginal() {
    let manifest = AssetManifest()
    #expect(manifest.resolve("missing.js") == "missing.js")
}

@Test func assetTypeDetectsCSS() {
    let detected = AssetType.detect(from: "style.css")
    #expect(detected == .css)
    #expect(detected?.mimeType == "text/css")
}

@Test func assetTypeDetectsJS() {
    let detected = AssetType.detect(from: "app.min.js")
    #expect(detected == .js)
    #expect(detected?.mimeType == "application/javascript")
}

@Test func assetTypeDetectsImages() {
    #expect(AssetType.detect(from: "logo.png") == .png)
    #expect(AssetType.detect(from: "photo.jpg") == .jpg)
    #expect(AssetType.detect(from: "icon.svg") == .svg)
    #expect(AssetType.detect(from: "hero.webp") == .webp)
    #expect(AssetType.detect(from: "art.avif") == .avif)
}

@Test func assetTypeDetectsFonts() {
    #expect(AssetType.detect(from: "inter.woff2") == .woff2)
    #expect(AssetType.detect(from: "roboto.ttf") == .ttf)
}

@Test func assetTypeDetectionIsCaseInsensitive() {
    #expect(AssetType.detect(from: "Style.CSS") == .css)
    #expect(AssetType.detect(from: "image.PNG") == .png)
}

@Test func assetTypeReturnsNilForUnknown() {
    #expect(AssetType.detect(from: "data.xyz") == nil)
    #expect(AssetType.detect(from: "noextension") == nil)
}

@Test func compressibleTypesAreTextBased() {
    #expect(AssetType.css.isCompressible)
    #expect(AssetType.js.isCompressible)
    #expect(AssetType.json.isCompressible)
    #expect(AssetType.html.isCompressible)
    #expect(AssetType.svg.isCompressible)
    #expect(AssetType.xml.isCompressible)
    #expect(AssetType.txt.isCompressible)
    #expect(AssetType.wasm.isCompressible)
}

@Test func binaryTypesAreNotCompressible() {
    #expect(!AssetType.png.isCompressible)
    #expect(!AssetType.jpg.isCompressible)
    #expect(!AssetType.gif.isCompressible)
    #expect(!AssetType.webp.isCompressible)
    #expect(!AssetType.woff2.isCompressible)
    #expect(!AssetType.mp4.isCompressible)
    #expect(!AssetType.pdf.isCompressible)
}

@Test func optimizerCompressesCompressibleTypes() {
    let optimizer = AssetOptimizer()
    let largeCSS = Data(String(repeating: "body { color: red; } ", count: 500).utf8)
    let result = optimizer.optimize(largeCSS, type: .css)
    #expect(result.originalSize == largeCSS.count)
    #expect(result.optimizedSize < result.originalSize)
    #expect(result.encoding == .deflate)
    #expect(result.savedBytes > 0)
    #expect(result.compressionRatio < 1.0)
}

@Test func optimizerSkipsBinaryTypes() {
    let optimizer = AssetOptimizer()
    let pngData = Data([0x89, 0x50, 0x4E, 0x47])
    let result = optimizer.optimize(pngData, type: .png)
    #expect(result.data == pngData)
    #expect(result.encoding == nil)
    #expect(result.savedBytes == 0)
    #expect(result.compressionRatio == 1.0)
}

@Test func optimizerHandlesEmptyData() {
    let optimizer = AssetOptimizer()
    let result = optimizer.optimize(Data(), type: .css)
    #expect(result.data.isEmpty)
    #expect(result.encoding == nil)
    #expect(result.compressionRatio == 1.0)
}

@Test func contentEncodingGzipValue() {
    #expect(ContentEncoding.deflate.value == "deflate")
}

@Test func contentEncodingEquality() {
    let a = ContentEncoding(value: "deflate")
    let b = ContentEncoding.deflate
    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
}

// MARK: - AssetType additional coverage

@Test func assetTypeDetectsAllKnownTypes() {
    let cases: [(String, String)] = [
        ("data.json", "application/json"),
        ("page.html", "text/html"),
        ("photo.jpeg", "image/jpeg"),
        ("icon.gif", "image/gif"),
        ("fav.ico", "image/x-icon"),
        ("font.woff", "font/woff"),
        ("font.otf", "font/otf"),
        ("app.webmanifest", "application/manifest+json"),
        ("doc.xml", "application/xml"),
        ("notes.txt", "text/plain"),
        ("doc.pdf", "application/pdf"),
        ("video.mp4", "video/mp4"),
        ("video.webm", "video/webm"),
        ("audio.mp3", "audio/mpeg"),
        ("app.wasm", "application/wasm"),
    ]
    for (filename, mime) in cases {
        let detected = AssetType.detect(from: filename)
        #expect(detected?.mimeType == mime, "Expected \(mime) for \(filename)")
    }
}

@Test func webmanifestIsCompressible() {
    #expect(AssetType.webmanifest.isCompressible)
}

@Test func optimizerReturnsFallbackWhenCompressionDoesNotHelp() {
    // Very small compressible data: compression may not reduce size
    let optimizer = AssetOptimizer()
    let tinyData = Data("a".utf8)
    let result = optimizer.optimize(tinyData, type: .css)
    // Either compressed or not — result should always be valid
    #expect(result.originalSize == tinyData.count)
    #expect(result.compressionRatio <= 1.0 || result.compressionRatio == 1.0)
}

// MARK: - AssetPipeline tests

/// Returns the real (symlink-resolved) path of a URL on macOS.
private func realPath(_ url: URL) -> String {
    var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
    return url.path.withCString { ptr in
        guard Darwin.realpath(ptr, &buf) != nil else { return url.path }
        return buf.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return url.path }
            return String(cString: base)
        }
    }
}

@Test func pipelineCreatesManifestFromSourceDirectory() throws {
    let tmp = FileManager.default.temporaryDirectory
    let sourceDirURL = tmp.appendingPathComponent("pipe-src-\(UUID().uuidString)")
    let outputDirURL = tmp.appendingPathComponent("pipe-out-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: sourceDirURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: sourceDirURL)
        try? FileManager.default.removeItem(at: outputDirURL)
    }

    // Use the real (symlink-resolved) path so the pipeline's path prefix replacement works
    let sourcePath = realPath(sourceDirURL)
    let outputPath =
        realPath(outputDirURL.deletingLastPathComponent())
        + "/" + outputDirURL.lastPathComponent

    let largeCSS = String(repeating: "body { color: red; } ", count: 100)
    try largeCSS.write(
        to: URL(fileURLWithPath: sourcePath + "/main.css"), atomically: true, encoding: .utf8)

    let pipeline = AssetPipeline(sourceDirectory: sourcePath, outputDirectory: outputPath)
    let manifest = try pipeline.process()

    let resolved = manifest.resolve("main.css")
    #expect(resolved != "main.css")
    #expect(resolved.hasPrefix("main-"))
    #expect(resolved.hasSuffix(".css"))
    #expect(FileManager.default.fileExists(atPath: outputPath))
}

@Test func pipelineHandlesBinaryAssets() throws {
    let tmp = FileManager.default.temporaryDirectory
    let sourceDirURL = tmp.appendingPathComponent("pipe-bin-\(UUID().uuidString)")
    let outputDirURL = tmp.appendingPathComponent("pipe-bin-out-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: sourceDirURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: sourceDirURL)
        try? FileManager.default.removeItem(at: outputDirURL)
    }

    let sourcePath = realPath(sourceDirURL)
    let outputPath =
        realPath(outputDirURL.deletingLastPathComponent())
        + "/" + outputDirURL.lastPathComponent

    try Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]).write(
        to: URL(fileURLWithPath: sourcePath + "/logo.png"))

    let pipeline = AssetPipeline(sourceDirectory: sourcePath, outputDirectory: outputPath)
    let manifest = try pipeline.process()

    let resolved = manifest.resolve("logo.png")
    #expect(resolved != "logo.png")
    #expect(resolved.hasSuffix(".png"))
}

@Test func pipelineHandlesNestedSubdirectories() throws {
    let tmp = FileManager.default.temporaryDirectory
    let sourceDirURL = tmp.appendingPathComponent("pipe-nested-\(UUID().uuidString)")
    let outputDirURL = tmp.appendingPathComponent("pipe-nested-out-\(UUID().uuidString)")
    let subdirURL = sourceDirURL.appendingPathComponent("css")
    try FileManager.default.createDirectory(at: subdirURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: sourceDirURL)
        try? FileManager.default.removeItem(at: outputDirURL)
    }

    let sourcePath = realPath(sourceDirURL)
    let outputPath =
        realPath(outputDirURL.deletingLastPathComponent())
        + "/" + outputDirURL.lastPathComponent

    try "body {}".write(
        to: URL(fileURLWithPath: sourcePath + "/css/style.css"), atomically: true, encoding: .utf8)

    let pipeline = AssetPipeline(sourceDirectory: sourcePath, outputDirectory: outputPath)
    let manifest = try pipeline.process()

    let resolved = manifest.resolve("css/style.css")
    #expect(resolved.hasPrefix("css/style-"))
    #expect(resolved.hasSuffix(".css"))
}

@Test func pipelineHandlesUnknownAssetType() throws {
    let tmp = FileManager.default.temporaryDirectory
    let sourceDirURL = tmp.appendingPathComponent("pipe-unk-\(UUID().uuidString)")
    let outputDirURL = tmp.appendingPathComponent("pipe-unk-out-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: sourceDirURL, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: sourceDirURL)
        try? FileManager.default.removeItem(at: outputDirURL)
    }

    let sourcePath = realPath(sourceDirURL)
    let outputPath =
        realPath(outputDirURL.deletingLastPathComponent())
        + "/" + outputDirURL.lastPathComponent

    // Unknown extension → exercises the `outputData = data` path (nil assetType)
    try "some data".write(
        to: URL(fileURLWithPath: sourcePath + "/data.xyz"), atomically: true, encoding: .utf8)

    let pipeline = AssetPipeline(sourceDirectory: sourcePath, outputDirectory: outputPath)
    let manifest = try pipeline.process()

    let resolved = manifest.resolve("data.xyz")
    #expect(resolved.hasPrefix("data-"))
    #expect(resolved.hasSuffix(".xyz"))
}

@Test func pipelineReturnsEmptyManifestForNonexistentSource() throws {
    let tmp = FileManager.default.temporaryDirectory
    let id = UUID().uuidString
    let sourceDir = tmp.appendingPathComponent("pipe-missing-\(id)")
    let outputDir = tmp.appendingPathComponent("pipe-missing-out-\(id)")
    defer { try? FileManager.default.removeItem(at: outputDir) }

    let pipeline = AssetPipeline(sourceDirectory: sourceDir.path, outputDirectory: outputDir.path)
    let manifest = try pipeline.process()

    #expect(manifest.resolve("style.css") == "style.css")
}

// MARK: - AssetFingerprint hash(contentsOf:)

@Test func fingerprintHashContentsOf() throws {
    let tmp = FileManager.default.temporaryDirectory
    let fileURL = tmp.appendingPathComponent("fp-test-\(UUID().uuidString).txt")
    let content = Data("hello fingerprint".utf8)
    try content.write(to: fileURL)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    let fromFile = try AssetFingerprint.hash(contentsOf: fileURL.path)
    let fromData = AssetFingerprint.hash(content)
    #expect(fromFile == fromData)
    #expect(fromFile.count == 8)
}

// MARK: - AssetManifest.make(from:)

@Test func manifestBuildFromDirectory() throws {
    let tmp = FileManager.default.temporaryDirectory
    let dirURL = tmp.appendingPathComponent("manifest-build-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dirURL) }

    let dirPath = realPath(dirURL)
    try Data("body { color: red; }".utf8).write(
        to: URL(fileURLWithPath: dirPath + "/main.css"))
    try Data([0x89, 0x50, 0x4E, 0x47]).write(
        to: URL(fileURLWithPath: dirPath + "/logo.png"))

    let manifest = try AssetManifest.make(from: dirPath)
    #expect(manifest.resolve("main.css") != "main.css")
    #expect(manifest.resolve("main.css").hasPrefix("main-"))
    #expect(manifest.resolve("main.css").hasSuffix(".css"))
    #expect(manifest.resolve("logo.png") != "logo.png")
    #expect(manifest.resolve("logo.png").hasSuffix(".png"))
}

@Test func manifestBuildFromDirectoryWithSubdirectory() throws {
    let tmp = FileManager.default.temporaryDirectory
    let dirURL = tmp.appendingPathComponent("manifest-nested-\(UUID().uuidString)")
    let subdirURL = dirURL.appendingPathComponent("css")
    try FileManager.default.createDirectory(at: subdirURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dirURL) }

    let dirPath = realPath(dirURL)
    try Data("h1 {}".utf8).write(
        to: URL(fileURLWithPath: dirPath + "/css/style.css"))

    let manifest = try AssetManifest.make(from: dirPath)
    let resolved = manifest.resolve("css/style.css")
    #expect(resolved.hasPrefix("css/style-"))
    #expect(resolved.hasSuffix(".css"))
}

@Test func manifestBuildFromEmptyDirectory() throws {
    let tmp = FileManager.default.temporaryDirectory
    let dirURL = tmp.appendingPathComponent("manifest-empty-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dirURL) }

    let manifest = try AssetManifest.make(from: dirURL.path)
    #expect(manifest.resolve("anything.css") == "anything.css")
}
