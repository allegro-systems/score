/// A type-erased node that wraps any concrete `Node` value.
///
/// `Content` enables components to accept arbitrary child nodes without
/// requiring a generic type parameter. It stores the wrapped node internally
/// and delegates rendering and tree walking to the underlying value.
///
/// You typically don't create `Content` values directly. Instead, declare a
/// `content` property of type `Content` on your component and apply the
/// `@Component` macro, which generates an initializer with a `@NodeBuilder`
/// trailing-closure parameter:
///
/// ```swift
/// @Component
/// struct Card {
///     let content: Content
///
///     var body: some Node {
///         Article { content }
///             .padding(16)
///     }
/// }
///
/// // Usage:
/// Card {
///     Heading(.two) { "Hello" }
///     Paragraph { "World" }
/// }
/// ```
public struct Content: Node {
    package let wrapped: any Node

    /// Creates a type-erased node wrapping the given value.
    ///
    /// - Parameter node: The node to wrap.
    public init(_ node: some Node) {
        self.wrapped = node
    }

    public var body: Never { fatalError() }
}
