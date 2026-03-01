import Testing

@testable import ScoreRuntime

private struct TestError: Error, CustomStringConvertible {
    let description: String
}

@Test func errorOverlayIncludesErrorMessageInDev() {
    let error = TestError(description: "Something broke")
    let html = ErrorOverlay.render(error, path: "/about", environment: .development)

    #expect(html.contains("Something broke"))
    #expect(html.contains("TestError"))
    #expect(html.contains("/about"))
    #expect(html.contains("Score"))
}

@Test func errorOverlayIncludesStackFrames() {
    let error = TestError(description: "nil value")
    let frames: [ErrorOverlay.Frame] = [
        .init(label: "render()", file: "Sources/App/AboutPage.swift", line: 34, column: 12),
        .init(label: "handleRequest()", file: "Sources/ScoreRuntime/Server.swift", line: 45),
    ]
    let html = ErrorOverlay.render(error, path: "/about", frames: frames, environment: .development)

    #expect(html.contains("Stack Trace"))
    #expect(html.contains("render()"))
    #expect(html.contains("AboutPage.swift"))
    #expect(html.contains(":34"))
    #expect(html.contains("vscode://"))
}

@Test func errorOverlayProductionHidesDetails() {
    let error = TestError(description: "secret database info")
    let html = ErrorOverlay.render(error, path: "/admin", environment: .production)

    #expect(!html.contains("secret database info"))
    #expect(!html.contains("TestError"))
    #expect(!html.contains("/admin"))
    #expect(html.contains("Something went wrong"))
}

@Test func errorOverlayEscapesHTML() {
    let error = TestError(description: "<script>alert('xss')</script>")
    let html = ErrorOverlay.render(error, path: "/test", environment: .development)

    #expect(!html.contains("<script>alert"))
    #expect(html.contains("&lt;script&gt;"))
}

@Test func errorOverlayFrameWithoutColumn() {
    let error = TestError(description: "test")
    let frames: [ErrorOverlay.Frame] = [
        .init(label: "func()", file: "Test.swift", line: 10)
    ]
    let html = ErrorOverlay.render(error, path: "/", frames: frames, environment: .development)

    #expect(html.contains("Test.swift:10"))
}

@Test func errorOverlayFrameWithColumn() {
    let error = TestError(description: "test")
    let frames: [ErrorOverlay.Frame] = [
        .init(label: "func()", file: "Test.swift", line: 10, column: 5)
    ]
    let html = ErrorOverlay.render(error, path: "/", frames: frames, environment: .development)

    #expect(html.contains("Test.swift:10:5"))
}
