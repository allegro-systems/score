import ScoreCSS
import ScoreCore
import ScoreHTML

/// A test helper that renders a node to HTML and CSS for assertions.
///
/// ### Example
///
/// ```swift
/// let result = TestRenderer.render {
///     Heading { "Hello" }
///         .font(size: 24)
/// }
/// #expect(result.html.contains("<h1"))
/// #expect(result.css.contains("font-size"))
/// ```
public struct TestRenderer: Sendable {

    /// The result of rendering a node for testing.
    public struct RenderOutput: Sendable {
        /// The rendered HTML string.
        public let html: String
        /// The collected CSS rules.
        public let rules: [CSSCollector.Rule]
    }

    /// Renders a node to HTML and collected CSS rules.
    public static func render(@NodeBuilder _ content: () -> some Node) -> RenderOutput {
        let node = content()
        let renderer = HTMLRenderer()
        let html = renderer.render(node)
        var collector = CSSCollector()
        collector.collect(from: node)
        let rules = collector.collectedRules()
        return RenderOutput(html: html, rules: rules)
    }

    /// Renders a node to an HTML string only.
    public static func renderHTML(@NodeBuilder _ content: () -> some Node) -> String {
        let renderer = HTMLRenderer()
        return renderer.render(content())
    }
}
