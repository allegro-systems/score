/// A node that renders a raw string without any escaping or transformation.
///
/// `RawTextNode` is a primitive leaf node that emits its content verbatim
/// into the rendered output. Unlike ``TextNode``, which is subject to HTML
/// entity escaping by the renderer, `RawTextNode` bypasses all escaping.
///
/// Use this node when you need to inject pre-built markup such as MathML,
/// SVG, or other trusted HTML fragments that must not be modified by the
/// rendering pipeline.
///
/// ```swift
/// RawTextNode("<math><mi>x</mi></math>")
/// ```
///
/// - Warning: The content is emitted without sanitisation. Never use
///   `RawTextNode` with untrusted user input, as it can introduce XSS
///   vulnerabilities.
///
/// - Note: `RawTextNode` is a primitive node — its `body` property is `Never`
///   and must never be called directly.
public struct RawTextNode: Node {

    /// The raw string content that will be emitted verbatim into the output.
    ///
    /// No escaping or transformation is applied to this value by the renderer.
    public let content: String

    /// Creates a raw text node with the given string content.
    ///
    /// - Parameter content: The raw string to emit without escaping.
    public init(_ content: String) {
        self.content = content
    }

    /// The body of `RawTextNode`, which is never accessible at runtime.
    ///
    /// `RawTextNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}
