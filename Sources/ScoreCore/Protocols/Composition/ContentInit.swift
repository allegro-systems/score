/// Generates a `@NodeBuilder` initializer for a generic layout component.
///
/// Apply `@ContentInit` to a struct that has a `content` stored property
/// of a generic `Node`-constrained type. The macro synthesizes an
/// `init(@NodeBuilder content: () -> Content)` so callers can use
/// trailing-closure syntax without writing the initializer by hand.
///
/// ### Example
///
/// ```swift
/// @ContentInit
/// struct CardLayout<Content: Node>: Component {
///     let content: Content
///
///     var body: some Node {
///         Article { content }
///             .padding(16)
///     }
/// }
///
/// // Usage — no init needed:
/// CardLayout {
///     Heading(.two) { "Hello" }
///     Paragraph { "World" }
/// }
/// ```
@attached(member, names: named(init))
public macro ContentInit() = #externalMacro(module: "ScoreMacros", type: "ContentInitMacro")
