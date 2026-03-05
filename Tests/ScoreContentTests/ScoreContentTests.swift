import Foundation
import Testing

@testable import ScoreContent
@testable import ScoreHTML

@Test func frontMatterParsesKeyValuePairs() {
    let content = """
        ---
        title: Hello World
        date: 2026-01-15
        draft: false
        ---
        Body content here.
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm != nil)
    #expect(fm?.string("title") == "Hello World")
    #expect(fm?.string("date") == "2026-01-15")
    #expect(fm?.bool("draft") == false)
}

@Test func frontMatterReturnsNilWithoutDelimiters() {
    let content = "No front matter here."
    let fm = FrontMatter.parse(from: content)
    #expect(fm == nil)
}

@Test func frontMatterReturnsNilWithoutClosingDelimiter() {
    let content = """
        ---
        title: Oops
        Body without closing delimiter.
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm == nil)
}

@Test func frontMatterStripsQuotedValues() {
    let content = """
        ---
        title: "Quoted Title"
        author: 'Single Quoted'
        ---
        Body.
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm?.string("title") == "Quoted Title")
    #expect(fm?.string("author") == "Single Quoted")
}

@Test func frontMatterParsesIntegerValues() {
    let content = """
        ---
        count: 42
        ---
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm?.integer("count") == 42)
    #expect(fm?.integer("missing") == nil)
}

@Test func frontMatterParsesBooleanVariants() {
    let content = """
        ---
        a: true
        b: yes
        c: 1
        d: false
        e: no
        f: 0
        ---
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm?.bool("a") == true)
    #expect(fm?.bool("b") == true)
    #expect(fm?.bool("c") == true)
    #expect(fm?.bool("d") == false)
    #expect(fm?.bool("e") == false)
    #expect(fm?.bool("f") == false)
}

@Test func frontMatterParsesCommaSeparatedList() {
    let content = """
        ---
        tags: swift, score, web
        ---
        """
    let fm = FrontMatter.parse(from: content)
    #expect(fm?.list("tags") == ["swift", "score", "web"])
    #expect(fm?.list("missing") == [])
}

@Test func frontMatterBodyStripping() {
    let content = """
        ---
        title: Hello
        ---
        Body content here.
        """
    let body = FrontMatter.body(from: content)
    #expect(body == "Body content here.")
}

@Test func frontMatterBodyWithoutFrontMatter() {
    let content = "Just content."
    let body = FrontMatter.body(from: content)
    #expect(body == "Just content.")
}

@Test func markdownConverterHandlesHeadings() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("# Title\n\n## Subtitle")
    #expect(blocks.count == 2)
    guard case .heading(let level1, _) = blocks[0] else {
        Issue.record("Expected heading")
        return
    }
    #expect(level1 == .one)
    guard case .heading(let level2, _) = blocks[1] else {
        Issue.record("Expected heading")
        return
    }
    #expect(level2 == .two)
}

@Test func markdownConverterHandlesParagraphs() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("Hello world")
    #expect(blocks.count == 1)
    guard case .paragraph(let children) = blocks[0] else {
        Issue.record("Expected paragraph")
        return
    }
    guard case .text(let text) = children.first else {
        Issue.record("Expected text inline")
        return
    }
    #expect(text == "Hello world")
}

@Test func markdownConverterHandlesLinks() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("[Score](https://example.com)")
    guard case .paragraph(let children) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    guard case .link(let dest, let linkChildren) = children.first else {
        Issue.record("Expected link")
        return
    }
    #expect(dest == "https://example.com")
    guard case .text(let text) = linkChildren.first else {
        Issue.record("Expected text")
        return
    }
    #expect(text == "Score")
}

@Test func markdownConverterHandlesEmphasisAndStrong() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("*italic* and **bold**")
    guard case .paragraph(let children) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    guard case .emphasis = children[0] else {
        Issue.record("Expected emphasis")
        return
    }
    guard case .strong = children[2] else {
        Issue.record("Expected strong")
        return
    }
}

@Test func markdownConverterHandlesInlineCode() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("Use `print()` for output")
    guard case .paragraph(let children) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    let codeInlines = children.filter {
        if case .code = $0 { return true }
        return false
    }
    #expect(codeInlines.count == 1)
}

@Test func markdownConverterHandlesCodeBlocks() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("```swift\nlet x = 1\n```")
    guard case .codeBlock(let code, let lang, _) = blocks.first else {
        Issue.record("Expected code block")
        return
    }
    #expect(lang == "swift")
    #expect(code.contains("let x = 1"))
}

@Test func markdownConverterHandlesMathBlocks() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("```math\nE = mc^2\n```")
    guard case .math(let latex) = blocks.first else {
        Issue.record("Expected math block")
        return
    }
    #expect(latex == "E = mc^2")
}

@Test func markdownConverterHandlesBlockquotes() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("> A quote")
    guard case .blockquote(let children) = blocks.first else {
        Issue.record("Expected blockquote")
        return
    }
    #expect(!children.isEmpty)
}

@Test func markdownConverterHandlesUnorderedLists() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("- one\n- two\n- three")
    guard case .unorderedList(let items) = blocks.first else {
        Issue.record("Expected unordered list")
        return
    }
    #expect(items.count == 3)
}

@Test func markdownConverterHandlesOrderedLists() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("1. first\n2. second")
    guard case .orderedList(let items) = blocks.first else {
        Issue.record("Expected ordered list")
        return
    }
    #expect(items.count == 2)
}

@Test func markdownConverterHandlesThematicBreak() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("above\n\n---\n\nbelow")
    let hasBreak = blocks.contains { block in
        if case .thematicBreak = block { return true }
        return false
    }
    #expect(hasBreak)
}

@Test func markdownConverterHandlesImages() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("![Alt text](image.png)")
    guard case .paragraph(let children) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    guard case .image(let src, let alt) = children.first else {
        Issue.record("Expected image")
        return
    }
    #expect(src == "image.png")
    #expect(alt == "Alt text")
}

@Test func syntaxThemeBuiltInsAreDistinct() {
    let themes: [SyntaxTheme] = [
        .scoreDefault, .vesper, .rosePine, .rosePineMoon, .rosePineDawn,
        .catppuccinLatte, .catppuccinFrappe, .catppuccinMacchiato,
        .catppuccinMocha, .nord, .tokyoNight, .githubLight,
    ]
    #expect(themes.count == 12)
    var unique: Set<SyntaxTheme> = []
    for theme in themes {
        unique.insert(theme)
    }
    #expect(unique.count == 12)
}

@Test func syntaxThemeHasExpectedProperties() {
    let theme = SyntaxTheme.scoreDefault
    #expect(theme.background.lightness < theme.variable.lightness)
    #expect(theme.keyword.chroma > 0)
    #expect(theme.comment.chroma < theme.keyword.chroma)
}

@Test func colorValueCSSOutput() {
    let color = ColorValue.oklch(0.72, 0.18, 310)
    #expect(color.cssValue == "oklch(0.72 0.18 310.0)")
}

@Test func contentCollectionIndexesItems() {
    let items = [
        ContentCollection.Item(slug: "hello", filename: "hello.md", frontMatter: FrontMatter(values: ["title": "Hello"]), body: "# Hello"),
        ContentCollection.Item(slug: "world", filename: "world.md", frontMatter: FrontMatter(values: ["title": "World"]), body: "# World"),
    ]
    let collection = ContentCollection(items: items)
    #expect(collection.count == 2)
    #expect(collection.item(slug: "hello")?.frontMatter?.string("title") == "Hello")
    #expect(collection.item(slug: "world")?.frontMatter?.string("title") == "World")
    #expect(collection.item(slug: "missing") == nil)
}

@Test func contentCollectionSortsByKey() {
    let items = [
        ContentCollection.Item(slug: "b", filename: "b.md", frontMatter: FrontMatter(values: ["date": "2026-02-01"]), body: "B"),
        ContentCollection.Item(slug: "a", filename: "a.md", frontMatter: FrontMatter(values: ["date": "2026-01-01"]), body: "A"),
        ContentCollection.Item(slug: "c", filename: "c.md", frontMatter: FrontMatter(values: ["date": "2026-03-01"]), body: "C"),
    ]
    let collection = ContentCollection(items: items)
    let sorted = collection.sorted(by: "date")
    #expect(sorted.items[0].slug == "a")
    #expect(sorted.items[1].slug == "b")
    #expect(sorted.items[2].slug == "c")
}

@Test func contentCollectionSortsDescending() {
    let items = [
        ContentCollection.Item(slug: "a", filename: "a.md", frontMatter: FrontMatter(values: ["date": "2026-01-01"]), body: "A"),
        ContentCollection.Item(slug: "c", filename: "c.md", frontMatter: FrontMatter(values: ["date": "2026-03-01"]), body: "C"),
    ]
    let collection = ContentCollection(items: items)
    let sorted = collection.sorted(by: "date", ascending: false)
    #expect(sorted.items[0].slug == "c")
}

@Test func contentCollectionFilters() {
    let items = [
        ContentCollection.Item(slug: "draft", filename: "draft.md", frontMatter: FrontMatter(values: ["draft": "true"]), body: "Draft"),
        ContentCollection.Item(slug: "published", filename: "published.md", frontMatter: FrontMatter(values: ["draft": "false"]), body: "Published"),
    ]
    let collection = ContentCollection(items: items)
    let published = collection.filter { $0?.bool("draft") == false }
    #expect(published.count == 1)
    #expect(published.items[0].slug == "published")
}

@Test func contentCollectionUniqueValues() {
    let items = [
        ContentCollection.Item(slug: "a", filename: "a.md", frontMatter: FrontMatter(values: ["category": "blog"]), body: ""),
        ContentCollection.Item(slug: "b", filename: "b.md", frontMatter: FrontMatter(values: ["category": "docs"]), body: ""),
        ContentCollection.Item(slug: "c", filename: "c.md", frontMatter: FrontMatter(values: ["category": "blog"]), body: ""),
    ]
    let collection = ContentCollection(items: items)
    let categories = collection.uniqueValues(for: "category")
    #expect(categories == ["blog", "docs"])
}

@Test func contentCollectionUniqueTags() {
    let items = [
        ContentCollection.Item(slug: "a", filename: "a.md", frontMatter: FrontMatter(values: ["tags": "swift, web"]), body: ""),
        ContentCollection.Item(slug: "b", filename: "b.md", frontMatter: FrontMatter(values: ["tags": "web, score"]), body: ""),
    ]
    let collection = ContentCollection(items: items)
    let tags = collection.uniqueTags(for: "tags")
    #expect(tags == ["swift", "web", "score"])
}

@Test func contentCollectionEmptyBehavior() {
    let collection = ContentCollection(items: [])
    #expect(collection.isEmpty)
    #expect(collection.count == 0)
    #expect(collection.item(slug: "anything") == nil)
}

@Test func mathExpressionSimpleRendering() {
    let expr = MathExpression("x^2")
    #expect(expr.rawMathML.contains("<math>"))
    #expect(expr.rawMathML.contains("<msup>"))
    #expect(expr.rawMathML.contains("</math>"))
}

@Test func mathExpressionFractionRendering() {
    let expr = MathExpression("\\frac{a}{b}")
    #expect(expr.rawMathML.contains("<mfrac>"))
    #expect(expr.rawMathML.contains("<mi>a</mi>"))
    #expect(expr.rawMathML.contains("<mi>b</mi>"))
}

@Test func mathExpressionSqrtRendering() {
    let expr = MathExpression("\\sqrt{x}")
    #expect(expr.rawMathML.contains("<msqrt>"))
    #expect(expr.rawMathML.contains("<mi>x</mi>"))
}

@Test func mathExpressionGreekLetters() {
    let expr = MathExpression("\\alpha + \\beta")
    #expect(expr.rawMathML.contains("&#x03B1;"))
    #expect(expr.rawMathML.contains("&#x03B2;"))
}

@Test func codeBlockStructure() {
    let block = CodeBlock(code: "let x = 1", language: "swift", filename: "main.swift")
    let renderer = HTMLRenderer()
    let html = renderer.render(block)
    #expect(html.contains("main.swift"))
    #expect(html.contains("swift"))
    #expect(html.contains("let x = 1"))
    #expect(html.contains("Copy"))
}

@Test func markdownNodeRendersToHTML() {
    let node = MarkdownNode("# Hello\n\nWorld")
    let renderer = HTMLRenderer()
    let html = renderer.render(node)
    #expect(html.contains("Hello"))
    #expect(html.contains("World"))
}

// MARK: - MarkdownNode rendering (exercises BlockNodeView and InlineNodeView body)

@Test func markdownNodeRendersCodeBlock() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("```swift\nlet x = 42\n```"))
    #expect(html.contains("let x = 42"))
}

@Test func markdownNodeRendersMathBlock() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("```math\nE = mc^2\n```"))
    #expect(html.contains("<math>"))
}

@Test func markdownNodeRendersBlockquote() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("> A wise quote"))
    #expect(html.contains("A wise quote"))
    #expect(html.contains("<blockquote>"))
}

@Test func markdownNodeRendersUnorderedList() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("- Apple\n- Banana\n- Cherry"))
    #expect(html.contains("Apple"))
    #expect(html.contains("<ul>"))
    #expect(html.contains("<li>"))
}

@Test func markdownNodeRendersOrderedList() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("1. First\n2. Second\n3. Third"))
    #expect(html.contains("First"))
    #expect(html.contains("<ol>"))
}

@Test func markdownNodeRendersThematicBreak() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("Above\n\n---\n\nBelow"))
    #expect(html.contains("Above"))
    #expect(html.contains("<hr>"))
    #expect(html.contains("Below"))
}

@Test func markdownNodeRendersTable() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("| Name | Score |\n|------|-------|\n| Alice | 100 |"))
    #expect(html.contains("Name"))
    #expect(html.contains("Alice"))
    #expect(html.contains("<table>"))
}

@Test func markdownNodeRendersRawHTML() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("<div>raw block</div>"))
    #expect(html.contains("raw block"))
}

@Test func markdownNodeRendersInlineElements() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("**bold** and *italic* and `code`"))
    #expect(html.contains("bold"))
    #expect(html.contains("italic"))
    #expect(html.contains("code"))
    #expect(html.contains("<strong>"))
    #expect(html.contains("<em>"))
    #expect(html.contains("<code>"))
}

@Test func markdownNodeRendersImage() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("![Alt](photo.png)"))
    #expect(html.contains("photo.png"))
}

@Test func markdownNodeRendersLink() {
    let renderer = HTMLRenderer()
    let html = renderer.render(MarkdownNode("[Click here](https://example.com)"))
    #expect(html.contains("Click here"))
    #expect(html.contains("https://example.com"))
}

// MARK: - MarkdownConverter extended coverage

@Test func markdownConverterHandlesAllHeadingLevels() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("### H3\n#### H4\n##### H5\n###### H6")
    #expect(blocks.count == 4)
    guard case .heading(let l3, _) = blocks[0] else {
        Issue.record("Expected heading level 3")
        return
    }
    guard case .heading(let l4, _) = blocks[1] else {
        Issue.record("Expected heading level 4")
        return
    }
    guard case .heading(let l5, _) = blocks[2] else {
        Issue.record("Expected heading level 5")
        return
    }
    guard case .heading(let l6, _) = blocks[3] else {
        Issue.record("Expected heading level 6")
        return
    }
    #expect(l3 == .three)
    #expect(l4 == .four)
    #expect(l5 == .five)
    #expect(l6 == .six)
}

@Test func markdownConverterHandlesHTMLBlock() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("<div>raw html</div>")
    let hasRaw = blocks.contains {
        if case .rawHTML = $0 { return true }
        return false
    }
    #expect(hasRaw)
}

@Test func markdownConverterHandlesTable() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("| A | B |\n|---|---|\n| 1 | 2 |")
    guard case .table(let headers, let rows) = blocks.first else {
        Issue.record("Expected table")
        return
    }
    #expect(headers.count == 2)
    #expect(rows.count == 1)
}

@Test func markdownConverterHandlesSoftBreak() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("line one\nline two")
    guard case .paragraph(let inlines) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    #expect(inlines.count >= 2)
}

@Test func markdownConverterHandlesLineBreak() {
    let converter = MarkdownConverter()
    // Two trailing spaces before newline = hard line break
    let blocks = converter.convert("line one  \nline two")
    guard case .paragraph(let inlines) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    let hasLineBreak = inlines.contains {
        if case .lineBreak = $0 { return true }
        return false
    }
    #expect(hasLineBreak)
}

@Test func markdownConverterHandlesInlineHTML() {
    let converter = MarkdownConverter()
    let blocks = converter.convert("text <br/> more")
    guard case .paragraph(let inlines) = blocks.first else {
        Issue.record("Expected paragraph")
        return
    }
    let hasInlineHTML = inlines.contains {
        if case .rawInlineHTML = $0 { return true }
        return false
    }
    #expect(hasInlineHTML)
}

// MARK: - MathExpression extended coverage

@Test func mathExpressionSubscript() {
    let expr = MathExpression("x_i")
    #expect(expr.rawMathML.contains("<msub>"))
    #expect(expr.rawMathML.contains("<mi>i</mi>"))
}

@Test func mathExpressionSubscriptAtStart() {
    let expr = MathExpression("_i")
    #expect(expr.rawMathML.contains("<msub>"))
}

@Test func mathExpressionSuperscriptAtStart() {
    let expr = MathExpression("^2")
    #expect(expr.rawMathML.contains("<msup>"))
}

@Test func mathExpressionNumbers() {
    let expr = MathExpression("3.14")
    #expect(expr.rawMathML.contains("<mn>3.14</mn>"))
}

@Test func mathExpressionOperatorChars() {
    let expr = MathExpression("a+b=c")
    #expect(expr.rawMathML.contains("<mo>+</mo>"))
    #expect(expr.rawMathML.contains("<mo>=</mo>"))
}

@Test func mathExpressionBraceGroup() {
    let expr = MathExpression("{x+y}")
    #expect(expr.rawMathML.contains("<mrow>"))
}

@Test func mathExpressionUnknownCommand() {
    let expr = MathExpression("\\unknown")
    #expect(expr.rawMathML.contains("<mtext>\\unknown</mtext>"))
}

@Test func mathExpressionRemainingGreekLetters() {
    let letters: [(String, String)] = [
        ("\\gamma", "&#x03B3;"),
        ("\\delta", "&#x03B4;"),
        ("\\epsilon", "&#x03B5;"),
        ("\\theta", "&#x03B8;"),
        ("\\lambda", "&#x03BB;"),
        ("\\mu", "&#x03BC;"),
        ("\\pi", "&#x03C0;"),
        ("\\sigma", "&#x03C3;"),
        ("\\omega", "&#x03C9;"),
        ("\\phi", "&#x03C6;"),
    ]
    for (cmd, entity) in letters {
        let expr = MathExpression(cmd)
        #expect(expr.rawMathML.contains(entity), "Expected \(entity) for \(cmd)")
    }
}

@Test func mathExpressionRemainingOperators() {
    let cases: [(String, String)] = [
        ("\\sum", "&#x2211;"),
        ("\\prod", "&#x220F;"),
        ("\\int", "&#x222B;"),
        ("\\infty", "&#x221E;"),
        ("\\pm", "&#x00B1;"),
        ("\\times", "&#x00D7;"),
        ("\\div", "&#x00F7;"),
        ("\\leq", "&#x2264;"),
        ("\\geq", "&#x2265;"),
        ("\\neq", "&#x2260;"),
    ]
    for (cmd, entity) in cases {
        let expr = MathExpression(cmd)
        #expect(expr.rawMathML.contains(entity), "Expected \(entity) for \(cmd)")
    }
}

@Test func mathExpressionNestedSuperscript() {
    let expr = MathExpression("x^2^3")
    #expect(expr.rawMathML.contains("<msup>"))
}

@Test func mathExpressionSqrtNoGroup() {
    let expr = MathExpression("\\sqrt ")
    #expect(expr.rawMathML.contains("<msqrt>"))
}

// MARK: - ContentLoader tests

@Test func contentLoaderLoadsSingleFile() throws {
    let dir = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
        .appendingPathComponent("score-cl-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    let file = dir.appendingPathComponent("post.md")
    try "---\ntitle: Test Post\n---\nContent here.".write(
        to: file, atomically: true, encoding: .utf8)

    let loader = ContentLoader(directory: dir.path)
    let loaded = try loader.load(path: file.path)
    #expect(loaded.slug == "post")
    #expect(loaded.filename == "post.md")
    #expect(loaded.frontMatter?.string("title") == "Test Post")
    #expect(loaded.body.contains("Content here."))
}

@Test func contentLoaderLoadsAllFiles() throws {
    let dir = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
        .appendingPathComponent("score-cl-all-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    for name in ["alpha.md", "beta.md", "gamma.md"] {
        try "Content of \(name)".write(
            to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    try "ignored".write(
        to: dir.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

    let loader = ContentLoader(directory: dir.path)
    let all = try loader.loadAll()
    #expect(all.count == 3)
    #expect(all[0].slug == "alpha")
    #expect(all[1].slug == "beta")
    #expect(all[2].slug == "gamma")
}

@Test func contentLoaderReturnsEmptyForMissingDirectory() throws {
    let loader = ContentLoader(directory: "/nonexistent/\(UUID().uuidString)")
    let all = try loader.loadAll()
    #expect(all.isEmpty)
}

@Test func contentLoaderCustomExtension() throws {
    let dir = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
        .appendingPathComponent("score-cl-ext-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }

    try "body txt".write(
        to: dir.appendingPathComponent("page.txt"), atomically: true, encoding: .utf8)
    try "body md".write(
        to: dir.appendingPathComponent("page.md"), atomically: true, encoding: .utf8)

    let loader = ContentLoader(directory: dir.path, fileExtension: "txt")
    let all = try loader.loadAll()
    #expect(all.count == 1)
    #expect(all[0].slug == "page")
}
