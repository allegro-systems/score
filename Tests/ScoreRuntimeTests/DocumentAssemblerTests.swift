import Testing

@testable import ScoreRuntime

@Test func assembleTitleComposition() {
    let title = DocumentAssembler.composeTitle(page: "About", separator: " | ", site: "My App")
    #expect(title == "About | My App")
}

@Test func composeTitlePageOnly() {
    let title = DocumentAssembler.composeTitle(page: "About", separator: " | ", site: nil)
    #expect(title == "About")
}

@Test func composeTitleSiteOnly() {
    let title = DocumentAssembler.composeTitle(page: nil, separator: " | ", site: "My App")
    #expect(title == "My App")
}

@Test func composeTitleBothNil() {
    let title = DocumentAssembler.composeTitle(page: nil, separator: " | ", site: nil)
    #expect(title == nil)
}

@Test func assembleDoctype() {
    let parts = DocumentAssembler.Parts(bodyHTML: "")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.hasPrefix("<!DOCTYPE html>"))
}

@Test func assembleIncludesTitle() {
    let parts = DocumentAssembler.Parts(title: "Hello")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<title>Hello</title>"))
}

@Test func assembleOmitsTitleWhenNil() {
    let parts = DocumentAssembler.Parts()
    let html = DocumentAssembler.assemble(parts)
    #expect(!html.contains("<title>"))
}

@Test func assembleIncludesDescription() {
    let parts = DocumentAssembler.Parts(description: "A test page.")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<meta name=\"description\" content=\"A test page.\">"))
}

@Test func assembleIncludesKeywords() {
    let parts = DocumentAssembler.Parts(keywords: ["swift", "web"])
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<meta name=\"keywords\" content=\"swift, web\">"))
}


@Test func assembleIncludesBody() {
    let parts = DocumentAssembler.Parts(bodyHTML: "<h1>Hello</h1>")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<body>\n<h1>Hello</h1>"))
}

@Test func assembleIncludesStructuredData() {
    let parts = DocumentAssembler.Parts(structuredData: ["{\"@type\":\"WebPage\"}"])
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<script type=\"application/ld+json\">{\"@type\":\"WebPage\"}</script>"))
}

@Test func assembleIncludesScripts() {
    let parts = DocumentAssembler.Parts(scripts: ["<script src=\"app.js\"></script>"])
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<script src=\"app.js\"></script>"))
}

@Test func assembleCharsetAndViewport() {
    let parts = DocumentAssembler.Parts()
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<meta charset=\"utf-8\">"))
    #expect(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"))
}

@Test func assembleEscapesTitleWithHTMLEntities() {
    let parts = DocumentAssembler.Parts(title: "<script>alert('xss')</script>")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<title>&lt;script&gt;alert('xss')&lt;/script&gt;</title>"))
    #expect(!html.contains("<title><script>"))
}

@Test func assembleEscapesDescriptionWithQuotes() {
    let parts = DocumentAssembler.Parts(description: "A \"quoted\" & <tagged> page")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("content=\"A &quot;quoted&quot; &amp; &lt;tagged&gt; page\""))
}

@Test func assembleEscapesKeywords() {
    let parts = DocumentAssembler.Parts(keywords: ["<b>bold</b>", "safe"])
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("content=\"&lt;b&gt;bold&lt;/b&gt;, safe\""))
}

@Test func assembleEmitsDataThemeWhenSet() {
    let parts = DocumentAssembler.Parts(activeTheme: "ocean")
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<html lang=\"en\" data-theme=\"ocean\">"))
}

@Test func assembleOmitsDataThemeWhenNil() {
    let parts = DocumentAssembler.Parts()
    let html = DocumentAssembler.assemble(parts)
    #expect(html.contains("<html lang=\"en\">"))
    #expect(!html.contains("data-theme"))
}
