import ScoreCore
import os

/// Information about a component scope for state emission.
public struct ScopeInfo: Sendable {
    /// The scope name (e.g. "counter", "accordion").
    public let name: String
    /// State entries as `(name, jsonValue)` pairs.
    public let states: [(name: String, value: String)]

    public init(name: String, states: [(name: String, value: String)]) {
        self.name = name
        self.states = states
    }
}

/// Renders a Score `Node` tree into an HTML string.
///
/// `HTMLRenderer` recursively walks a node tree, dispatching on concrete
/// primitive node types to produce deterministic, diffable HTML output.
/// Composite nodes (those whose `Body` is not `Never`) are expanded by
/// calling their `body` property until a primitive is reached.
///
/// The renderer handles HTML entity escaping for text content and attribute
/// values, ensuring the output is safe for embedding in an HTML document.
///
/// ### Example
///
/// ```swift
/// let renderer = HTMLRenderer()
/// let html = renderer.render(
///     Stack {
///         Heading(.one) { "Hello" }
///         Paragraph { "Welcome to Score." }
///     }
/// )
/// // html == "<div><h1>Hello</h1><p>Welcome to Score.</p></div>"
/// ```
///
/// - Note: `HTMLRenderer` is designed for server-side use and produces
///   static HTML. Interactive behaviour requires the Score runtime.
public struct HTMLRenderer: Sendable {

    /// Mutable render-time context shared across the rendering pass.
    ///
    /// Mutable counter for `data-s` event binding indices, protected by a lock
    /// to prevent data races.
    final class RenderContext: Sendable {
        private let lock = OSAllocatedUnfairLock(initialState: 0)

        /// Returns the next event index and increments the counter.
        func nextEventIndex() -> Int {
            lock.withLock { index in
                let current = index
                index += 1
                return current
            }
        }
    }

    /// An optional closure that resolves CSS class names for modified nodes.
    ///
    /// When set, the renderer queries this closure for each `ModifiedNode`
    /// encountered during rendering. If the closure returns a non-nil class
    /// name, the node's content is wrapped in an element with that class.
    public var classInjector: (@Sendable ([any ModifierValue]) -> String?)?

    /// An optional closure that resolves a semantic CSS class name for
    /// composite nodes (Components, Pages).
    ///
    /// When set, the renderer calls this for each composite node before
    /// expanding its body. If it returns a non-nil class name, the body
    /// is wrapped in a `<div class="...">`.
    public var componentClassInjector: (@Sendable (Any) -> String?)?

    /// An optional closure that checks whether a node is a stateful
    /// component requiring a `data-scope` wrapper.
    ///
    /// When set, the renderer calls this for each composite node (Component)
    /// encountered during tree expansion. If it returns `ScopeInfo`, the
    /// component's body is wrapped in `<div data-scope="...">` with a
    /// hidden state element containing `data-as-value:*` attributes.
    public var scopeInjector: (@Sendable (Any) -> ScopeInfo?)?

    /// The render context tracking event indices.
    let context = RenderContext()

    /// Creates a new HTML renderer.
    public init() {}

    /// Creates an HTML renderer with a class injector.
    ///
    /// - Parameter classInjector: A closure that maps modifier arrays to
    ///   CSS class names. Return `nil` for modifier sets that produce no CSS.
    public init(classInjector: (@Sendable ([any ModifierValue]) -> String?)?) {
        self.classInjector = classInjector
    }

    /// Creates an HTML renderer with class and scope injectors.
    ///
    /// - Parameters:
    ///   - classInjector: A closure that maps modifier arrays to CSS class names.
    ///   - scopeInjector: A closure that returns scope info for stateful components.
    public init(
        classInjector: (@Sendable ([any ModifierValue]) -> String?)?,
        scopeInjector: (@Sendable (Any) -> ScopeInfo?)?
    ) {
        self.classInjector = classInjector
        self.scopeInjector = scopeInjector
    }

    /// Renders the given node tree into an HTML string.
    ///
    /// - Parameter node: The root node of the tree to render.
    /// - Returns: A string containing the rendered HTML.
    public func render(_ node: some Node) -> String {
        var output = ""
        output.reserveCapacity(4096)
        write(node, to: &output)
        return output
    }

    /// Writes a node to `output`, dispatching via `HTMLRenderable` or falling back to `body`.
    func write(_ node: some Node, to output: inout String) {
        if let renderable = node as? HTMLRenderable {
            renderable.renderHTML(into: &output, renderer: self)
            return
        }

        if node.body is Never { return }

        // Check if this is a stateful component needing a scope wrapper.
        if let scopeInfo = scopeInjector?(node) {
            output.append("<div data-scope=\"\(scopeInfo.name.attributeEscaped)\">")
            // Emit hidden state element with data-as-value attributes.
            output.append("<div hidden aria-hidden=\"true\"")
            for (name, value) in scopeInfo.states {
                output.append(" data-as-value:\(name)=\"\(value.attributeEscaped)\"")
            }
            output.append("></div>")
            write(node.body, to: &output)
            output.append("</div>")
        } else if let semanticClass = componentClassInjector?(node) {
            output.append("<div class=\"\(semanticClass.attributeEscaped)\">")
            write(node.body, to: &output)
            output.append("</div>")
        } else {
            write(node.body, to: &output)
        }
    }

    /// Emits an opening tag, recursively renders `content`, then emits the closing tag.
    func tag(_ name: String, _ attributes: [(String, String)] = [], content: some Node, to output: inout String) {
        output.append("<\(name)")
        writeAttributes(attributes, to: &output)
        output.append(">")
        write(content, to: &output)
        output.append("</\(name)>")
    }

    /// Emits a self-closing void element tag with no content.
    func voidTag(_ name: String, _ attributes: [(String, String)], to output: inout String) {
        output.append("<\(name)")
        writeAttributes(attributes, to: &output)
        output.append(">")
    }

    /// Appends each attribute to `output`; boolean attributes (empty value) are emitted without a value.
    func writeAttributes(_ attributes: [(String, String)], to output: inout String) {
        for (key, value) in attributes {
            if value.isEmpty {
                output.append(" \(key)")
            } else {
                output.append(" \(key)=\"\(value.attributeEscaped)\"")
            }
        }
    }

}
