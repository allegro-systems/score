import Testing

@testable import ScoreCore

@Test func sourceLocationCapturesDefaultValues() {
    let location = SourceLocation()
    #expect(location.fileID.hasSuffix("SourceLocationTests.swift"))
    #expect(location.line > 0)
    #expect(location.column > 0)
}

@Test func sourceLocationStoresExplicitValues() {
    let location = SourceLocation(fileID: "MyModule/File.swift", line: 42, column: 5)
    #expect(location.fileID == "MyModule/File.swift")
    #expect(location.line == 42)
    #expect(location.column == 5)
}

@Test func sourceLocationEquatable() {
    let a = SourceLocation(fileID: "A/B.swift", line: 1, column: 1)
    let b = SourceLocation(fileID: "A/B.swift", line: 1, column: 1)
    let c = SourceLocation(fileID: "A/B.swift", line: 2, column: 1)
    #expect(a == b)
    #expect(a != c)
}

@Test func paragraphConformsToSourceLocatable() {
    let node = Paragraph { TextNode("hello") }
    #expect(node.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
    #expect(node.sourceLocation.line > 0)
}

@Test func headingConformsToSourceLocatable() {
    let node = Heading(.two) { TextNode("title") }
    #expect(node.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
}

@Test func stackConformsToSourceLocatable() {
    let node = Stack { TextNode("content") }
    #expect(node.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
}

@Test func voidElementConformsToSourceLocatable() {
    let hr = HorizontalRule()
    #expect(hr.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))

    let br = LineBreak()
    #expect(br.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
}

@Test func imageConformsToSourceLocatable() {
    let img = Image(src: "/logo.png", alt: "Logo")
    #expect(img.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
}

@Test func inputConformsToSourceLocatable() {
    let input = Input(type: .text, name: "q")
    #expect(input.sourceLocation.fileID.hasSuffix("SourceLocationTests.swift"))
}

@Test func semanticContainersConformToSourceLocatable() {
    let main = Main { TextNode("m") }
    let section = Section { TextNode("s") }
    let article = Article { TextNode("a") }
    let header = Header { TextNode("h") }
    let footer = Footer { TextNode("f") }
    let aside = Aside { TextNode("a") }
    let nav = Navigation { TextNode("n") }

    #expect(main.sourceLocation.line > 0)
    #expect(section.sourceLocation.line > 0)
    #expect(article.sourceLocation.line > 0)
    #expect(header.sourceLocation.line > 0)
    #expect(footer.sourceLocation.line > 0)
    #expect(aside.sourceLocation.line > 0)
    #expect(nav.sourceLocation.line > 0)
}

@Test func controlNodesConformToSourceLocatable() {
    let button = Button { TextNode("click") }
    let form = Form(action: "/", method: .post) { TextNode("f") }
    let label = Label { TextNode("l") }

    #expect(button.sourceLocation.line > 0)
    #expect(form.sourceLocation.line > 0)
    #expect(label.sourceLocation.line > 0)
}

@Test func sourceLocationAcceptsExplicitOverride() {
    let node = Paragraph(
        file: "Custom/Module.swift", line: 99, column: 3
    ) { TextNode("test") }
    #expect(node.sourceLocation.fileID == "Custom/Module.swift")
    #expect(node.sourceLocation.line == 99)
    #expect(node.sourceLocation.column == 3)
}
