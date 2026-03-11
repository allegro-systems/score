import Foundation
import ScoreCore
import Testing

@testable import ScoreRuntime

private struct MinimalEmitterTheme: Theme {
    var name: String? { nil }
    var colorRoles: [String: ColorToken] { [:] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { [:] }
    var typeScaleBase: Double { 16 }
    var typeScaleRatio: Double { 1.25 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
}

private struct EmitterHomePage: Page {
    static let path = "/"
    var metadata: (any Metadata)? { SiteMetadata(title: "Home") }
    var body: some Node {
        Heading(.one) { Text(verbatim: "Welcome") }
    }
}

private struct EmitterAboutPage: Page {
    static let path = "/about"
    var metadata: (any Metadata)? { SiteMetadata(title: "About") }
    var body: some Node {
        Paragraph { Text(verbatim: "About us") }
    }
}

private struct EmitterApp: Application {
    var pages: [any Page] { [EmitterHomePage(), EmitterAboutPage()] }
    var controllers: [any Controller] { [] }
    var theme: (any Theme)? { MinimalEmitterTheme() }
    var metadata: (any Metadata)? { nil }
    var outputDirectory: String = ""

    init() {}
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }
}

private struct EmptyEmitterApp: Application {
    var pages: [any Page] { [] }
    var controllers: [any Controller] { [] }
    var theme: (any Theme)? { nil }
    var metadata: (any Metadata)? { nil }
    var outputDirectory: String = ""

    init() {}
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }
}

@Test func emitCreatesOutputDirectory() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    #expect(FileManager.default.fileExists(atPath: tempDir))
}

@Test func emitCreatesGlobalCSS() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let cssPath = "\(tempDir)/global.css"
    #expect(FileManager.default.fileExists(atPath: cssPath))

    let css = try String(contentsOfFile: cssPath, encoding: .utf8)
    #expect(!css.isEmpty)
}

@Test func emitCreatesIndexHTML() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let indexPath = "\(tempDir)/index.html"
    #expect(FileManager.default.fileExists(atPath: indexPath))

    let html = try String(contentsOfFile: indexPath, encoding: .utf8)
    #expect(html.contains("<!DOCTYPE html>"))
    #expect(html.contains("Welcome"))
}

@Test func emitCreatesNestedPageFile() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let aboutPath = "\(tempDir)/about.html"
    #expect(FileManager.default.fileExists(atPath: aboutPath))

    let html = try String(contentsOfFile: aboutPath, encoding: .utf8)
    #expect(html.contains("About us"))
}

@Test func emitWithNoPages() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmptyEmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let cssPath = "\(tempDir)/global.css"
    #expect(FileManager.default.fileExists(atPath: cssPath))
}

@Test func emitGlobalCSSContainsThemeTokens() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let css = try String(contentsOfFile: "\(tempDir)/global.css", encoding: .utf8)
    #expect(css.contains("spacing-unit"))
}

@Test func emitHTMLReferencesExternalAssets() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let html = try String(contentsOfFile: "\(tempDir)/index.html", encoding: .utf8)
    #expect(html.contains("global.css"))
}

@Test func missingResourceErrorDescription() {
    let error = StaticSiteEmitterError.missingResource("signal-polyfill")
    #expect(error.description.contains("signal-polyfill"))
    #expect(error.description.contains("Missing bundled resource"))
}
