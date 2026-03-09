import ScoreCore

// MARK: - Container Elements

/// A node that renders as a named HTML container element (`<tag>…</tag>`).
///
/// Conforming types provide a tag name and optional attributes; the
/// protocol supplies a default `HTMLRenderable` implementation that
/// calls `renderer.tag(...)`.
///
/// Most Score nodes are simple wrappers around an HTML tag — this
/// protocol eliminates the per-type rendering boilerplate.
protocol HTMLContainerElement: HTMLRenderable {
    associatedtype Content: Node
    /// The HTML tag name (e.g. `"p"`, `"div"`, `"section"`).
    var htmlTagName: String { get }
    /// The child node rendered between the opening and closing tags.
    var content: Content { get }
    /// HTML attributes emitted on the opening tag.
    var htmlAttributes: [(String, String)] { get }
}

extension HTMLContainerElement {
    var htmlAttributes: [(String, String)] { [] }

    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.tag(htmlTagName, htmlAttributes, content: content, to: &output)
    }
}

// MARK: - Void Elements

/// A node that renders as a self-closing HTML void element (`<tag>`).
///
/// Void elements have no children — only attributes.
protocol HTMLVoidElement: HTMLRenderable {
    /// The HTML tag name (e.g. `"input"`, `"img"`, `"hr"`).
    var htmlTagName: String { get }
    /// HTML attributes emitted on the tag.
    var htmlAttributes: [(String, String)] { get }
}

extension HTMLVoidElement {
    var htmlAttributes: [(String, String)] { [] }

    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.voidTag(htmlTagName, htmlAttributes, to: &output)
    }
}

// MARK: - Transparent Elements

/// A node that renders its children directly with no wrapping element.
protocol HTMLTransparentElement: HTMLRenderable {
    associatedtype Content: Node
    /// The child node rendered inline.
    var content: Content { get }
}

extension HTMLTransparentElement {
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.write(content, to: &output)
    }
}
