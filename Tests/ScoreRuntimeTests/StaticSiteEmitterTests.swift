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

private struct EmitterAppWithBaseURL: Application {
    var pages: [any Page] { [EmitterHomePage(), EmitterAboutPage()] }
    var controllers: [any Controller] { [] }
    var theme: (any Theme)? { MinimalEmitterTheme() }
    var metadata: (any Metadata)? { SiteMetadata(baseURL: "https://example.com") }
    var outputDirectory: String = ""

    init() {}
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }
}

private struct StatusPage: Page {
    static let path = "/404"
    var body: some Node {
        Heading(.one) { Text(verbatim: "Not Found") }
    }
}

private struct EmitterAppWithStatusPage: Application {
    var pages: [any Page] { [EmitterHomePage(), StatusPage()] }
    var controllers: [any Controller] { [] }
    var theme: (any Theme)? { MinimalEmitterTheme() }
    var metadata: (any Metadata)? { SiteMetadata(baseURL: "https://example.com") }
    var outputDirectory: String = ""

    init() {}
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }
}

@Test func emitCreatesSitemapWhenBaseURLIsSet() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterAppWithBaseURL(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let sitemapPath = "\(tempDir)/sitemap.xml"
    #expect(FileManager.default.fileExists(atPath: sitemapPath))

    let xml = try String(contentsOfFile: sitemapPath, encoding: .utf8)
    #expect(xml.contains("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"))
    #expect(xml.contains("<loc>https://example.com/</loc>"))
    #expect(xml.contains("<loc>https://example.com/about</loc>"))
}

@Test func emitSkipsSitemapWithoutBaseURL() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let sitemapPath = "\(tempDir)/sitemap.xml"
    #expect(!FileManager.default.fileExists(atPath: sitemapPath))
}

@Test func emitExcludesStatusPagesFromSitemap() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterAppWithStatusPage(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let xml = try String(contentsOfFile: "\(tempDir)/sitemap.xml", encoding: .utf8)
    #expect(xml.contains("<loc>https://example.com/</loc>"))
    #expect(!xml.contains("404"))
}

private struct TestErrorPage: ErrorPage {
    var context: ErrorContext

    init(context: ErrorContext) {
        self.context = context
    }

    var body: some Node {
        Heading(.one) { Text(verbatim: "Error \(context.statusCode)") }
        Paragraph { Text(verbatim: context.message) }
    }
}

private struct EmitterAppWithErrorPage: Application {
    var pages: [any Page] { [EmitterHomePage()] }
    var controllers: [any Controller] { [] }
    var theme: (any Theme)? { MinimalEmitterTheme() }
    var metadata: (any Metadata)? { nil }
    var outputDirectory: String = ""

    init() {}
    init(outputDirectory: String) { self.outputDirectory = outputDirectory }

    var errorPage: (any ErrorPage.Type)? { TestErrorPage.self }
}

@Test func emitCreates404HTMLWhenErrorPageProvided() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterAppWithErrorPage(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let errorPath = "\(tempDir)/404.html"
    #expect(FileManager.default.fileExists(atPath: errorPath))

    let html = try String(contentsOfFile: errorPath, encoding: .utf8)
    #expect(html.contains("Error 404"))
    #expect(html.contains("Not Found"))
}

@Test func emitSkips404HTMLWithoutErrorPage() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-emitter-test-\(UUID().uuidString)")
        .path
    defer { try? FileManager.default.removeItem(atPath: tempDir) }

    let app = EmitterApp(outputDirectory: tempDir)
    try StaticSiteEmitter.emit(application: app)

    let errorPath = "\(tempDir)/404.html"
    #expect(!FileManager.default.fileExists(atPath: errorPath))
}

@Test func missingResourceErrorDescription() {
    let error = StaticSiteEmitterError.missingResource("signal-polyfill")
    #expect(error.description.contains("signal-polyfill"))
    #expect(error.description.contains("Missing bundled resource"))
}
