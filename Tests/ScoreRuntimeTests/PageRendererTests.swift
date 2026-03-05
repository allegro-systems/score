import ScoreCore
import Testing

@testable import ScoreRuntime

private struct MinimalTheme: Theme {
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

private struct NamedMinimalTheme: Theme {
    var name: String? { "ocean" }
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

private let appMetadata = Metadata(
    site: "TestSite",
    titleSeparator: " — ",
    description: "Default description",
    keywords: ["swift"]
)

private struct SimplePage: Page {
    static let path = "/"
    var metadata: Metadata? { Metadata(title: "Home") }

    var body: some Node {
        Heading(.one) { Text(verbatim: "Hello") }
    }
}

private struct StyledPage: Page {
    static let path = "/styled"

    var body: some Node {
        Paragraph {
            Text(verbatim: "Padded text")
        }
        .padding(16)
    }
}

@Test func renderSimplePage() {
    let html = PageRenderer.render(page: SimplePage(), metadata: nil, theme: nil)
    #expect(html.contains("<!DOCTYPE html>"))
    #expect(html.contains("<h1>Hello</h1>"))
}

@Test func renderPageWithMetadata() {
    let html = PageRenderer.render(page: SimplePage(), metadata: appMetadata, theme: nil)
    #expect(html.contains("<title>Home — TestSite</title>"))
    #expect(html.contains("Default description"))
}

@Test func renderPageWithTheme() {
    let html = PageRenderer.render(page: SimplePage(), metadata: nil, theme: MinimalTheme())
    #expect(html.contains(":root {"))
    #expect(html.contains("--spacing-unit: 4px"))
}

@Test func renderStyledPageIncludesCSS() {
    let html = PageRenderer.render(page: StyledPage(), metadata: nil, theme: nil)
    #expect(html.contains("padding: 16px"))
}

@Test func renderStyledPageInjectsClass() {
    let html = PageRenderer.render(page: StyledPage(), metadata: nil, theme: nil)
    #expect(html.contains("<div class=\"s-"))
}

@Test func renderPageWithNamedThemeEmitsDataTheme() {
    let html = PageRenderer.render(page: SimplePage(), metadata: nil, theme: NamedMinimalTheme())
    #expect(html.contains("<html lang=\"en\" data-theme=\"ocean\">"))
}

@Test func renderPageWithUnnamedThemeOmitsDataTheme() {
    let html = PageRenderer.render(page: SimplePage(), metadata: nil, theme: MinimalTheme())
    #expect(html.contains("<html lang=\"en\">"))
    #expect(!html.contains("data-theme"))
}
