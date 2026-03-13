import ScoreCore
import Testing

@testable import ScoreRuntime

private struct MinimalTheme: Theme {
    var name: String? { nil }
    var colorRoles: [String: ColorToken] { [:] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { [:] }
    var typeScaleBase: Double { 16 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
    var named: [String: any ThemePatch] { [:] }
}

private struct NamedMinimalTheme: Theme {
    var name: String? { "ocean" }
    var colorRoles: [String: ColorToken] { [:] }
    var customColorRoles: [String: [Int: ColorToken]] { [:] }
    var fontFamilies: [String: String] { [:] }
    var typeScaleBase: Double { 16 }
    var spacingUnit: Double { 4 }
    var radiusBase: Double { 4 }
    var syntaxThemeName: String? { nil }
    var dark: (any ThemePatch)? { nil }
    var named: [String: any ThemePatch] { [:] }
}

private let appMetadata = SiteMetadata(
    site: "TestSite",
    titleSeparator: " — ",
    description: "Default description",
    keywords: ["swift"]
)

private struct SimplePage: Page {
    static let path = "/"
    var metadata: (any Metadata)? { SiteMetadata(title: "Home") }

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
    let result = PageRenderer.render(page: SimplePage(), metadata: nil, theme: nil)
    #expect(result.html.contains("<!DOCTYPE html>"))
    #expect(result.html.contains("<h1") && result.html.contains(">Hello</h1>"))
}

@Test func renderPageWithSiteMetadata() {
    let result = PageRenderer.render(page: SimplePage(), metadata: appMetadata, theme: nil)
    #expect(result.html.contains("<title>Home — TestSite</title>"))
    #expect(result.html.contains("Default description"))
}

@Test func renderPageWithTheme() {
    let result = PageRenderer.render(page: SimplePage(), metadata: nil, theme: MinimalTheme())
    #expect(result.html.contains("<!DOCTYPE html>"))
}

@Test func renderStyledPageIncludesCSS() {
    let result = PageRenderer.render(page: StyledPage(), metadata: nil, theme: nil)
    let hasCSS = result.componentCSS.contains("padding: 16px") || result.flatCSS.contains("padding: 16px")
    #expect(hasCSS)
}

@Test func renderStyledPageProducesHTML() {
    let result = PageRenderer.render(page: StyledPage(), metadata: nil, theme: nil)
    #expect(result.html.contains("<p"))
    #expect(result.html.contains("Padded text"))
}

@Test func renderPageWithNamedThemeEmitsDataTheme() {
    let result = PageRenderer.render(page: SimplePage(), metadata: nil, theme: NamedMinimalTheme())
    #expect(result.html.contains("<html lang=\"en\" data-theme=\"ocean\">"))
}

@Test func renderPageWithUnnamedThemeOmitsDataTheme() {
    let result = PageRenderer.render(page: SimplePage(), metadata: nil, theme: MinimalTheme())
    #expect(result.html.contains("<html lang=\"en\">"))
    #expect(!result.html.contains("<html lang=\"en\" data-theme"))
}
