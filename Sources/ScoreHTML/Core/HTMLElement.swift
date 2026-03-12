import ScoreCore

// MARK: - Attribute Injectable

/// A node that can render itself with additional attributes merged into
/// its opening tag.
///
/// `ModifiedNode` uses this protocol to apply CSS classes and HTML
/// attributes directly onto the inner element's tag instead of wrapping
/// it in an extra `<div>`.
protocol HTMLAttributeInjectable {
    /// Renders this element with extra attributes merged into its tag.
    ///
    /// - Parameters:
    ///   - extraAttributes: Additional attributes to merge (e.g. `class`,
    ///     `data-s`). If a `class` key exists in both the element's own
    ///     attributes and `extraAttributes`, the values are combined.
    ///   - output: The HTML output buffer.
    ///   - renderer: The renderer used for child content.
    func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    )
}

// MARK: - Container Elements

/// A node that renders as a named HTML container element (`<tag>…</tag>`).
///
/// Conforming types provide a tag name and optional attributes; the
/// protocol supplies a default `HTMLRenderable` implementation that
/// calls `renderer.tag(...)`.
///
/// Most Score nodes are simple wrappers around an HTML tag — this
/// protocol eliminates the per-type rendering boilerplate.
protocol HTMLContainerElement: HTMLRenderable, HTMLAttributeInjectable {
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
        var attrs = htmlAttributes
        if renderer.isDevMode, let loc = (self as? SourceLocatable)?.sourceLocation {
            attrs.append(("data-source", "\(loc.fileID):\(loc.line):\(loc.column)"))
            attrs.append(("data-source-path", "\(loc.filePath):\(loc.line):\(loc.column)"))
        }
        renderer.tag(htmlTagName, attrs, content: content, to: &output)
    }

    func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    ) {
        var merged = Self.mergeAttributes(htmlAttributes, extraAttributes)
        if renderer.isDevMode, let loc = (self as? SourceLocatable)?.sourceLocation {
            merged.append(("data-source", "\(loc.fileID):\(loc.line):\(loc.column)"))
            merged.append(("data-source-path", "\(loc.filePath):\(loc.line):\(loc.column)"))
        }
        renderer.tag(htmlTagName, merged, content: content, to: &output)
    }
}

// MARK: - Void Elements

/// A node that renders as a self-closing HTML void element (`<tag>`).
///
/// Void elements have no children — only attributes.
protocol HTMLVoidElement: HTMLRenderable, HTMLAttributeInjectable {
    /// The HTML tag name (e.g. `"input"`, `"img"`, `"hr"`).
    var htmlTagName: String { get }
    /// HTML attributes emitted on the tag.
    var htmlAttributes: [(String, String)] { get }
}

extension HTMLVoidElement {
    var htmlAttributes: [(String, String)] { [] }

    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var attrs = htmlAttributes
        if renderer.isDevMode, let loc = (self as? SourceLocatable)?.sourceLocation {
            attrs.append(("data-source", "\(loc.fileID):\(loc.line):\(loc.column)"))
            attrs.append(("data-source-path", "\(loc.filePath):\(loc.line):\(loc.column)"))
        }
        renderer.voidTag(htmlTagName, attrs, to: &output)
    }

    func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    ) {
        var merged = Self.mergeAttributes(htmlAttributes, extraAttributes)
        if renderer.isDevMode, let loc = (self as? SourceLocatable)?.sourceLocation {
            merged.append(("data-source", "\(loc.fileID):\(loc.line):\(loc.column)"))
            merged.append(("data-source-path", "\(loc.filePath):\(loc.line):\(loc.column)"))
        }
        renderer.voidTag(htmlTagName, merged, to: &output)
    }
}

// MARK: - Attribute Merging

extension HTMLAttributeInjectable {
    /// Merges two attribute lists, combining `class` values when both
    /// lists contain a `class` entry.
    static func mergeAttributes(
        _ base: [(String, String)],
        _ extra: [(String, String)]
    ) -> [(String, String)] {
        var result = base
        for (name, value) in extra {
            if name == "class", let index = result.firstIndex(where: { $0.0 == "class" }) {
                result[index].1 += " \(value)"
            } else {
                result.append((name, value))
            }
        }
        return result
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
