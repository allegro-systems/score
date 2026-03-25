import Testing

@testable import ScoreCore
@testable import ScoreTesting

@Suite("TestRenderer")
struct TestRendererTests {

    @Test("Renders HTML from node builder")
    func rendersHTML() {
        let result = TestRenderer.render {
            Heading(.one) { "Hello" }
        }
        #expect(result.html.contains("Hello"))
    }

    @Test("renderHTML returns string directly")
    func renderHTMLDirect() {
        let html = TestRenderer.renderHTML {
            Paragraph { "Test content" }
        }
        #expect(html.contains("Test content"))
    }
}
