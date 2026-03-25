/// The fundamental building block of a Score UI hierarchy.
///
/// `Node` is the core protocol that all renderable elements conform to. It
/// mirrors the composable tree model found in SwiftUI: each node declares
/// its structure by returning child nodes from its `body` property, and the
/// Score renderer recursively walks that tree to produce output (e.g. HTML).
///
/// Primitive nodes — such as `TextNode`, `TupleNode`, and `EmptyNode` —
/// are terminal nodes whose `body` property is `Never`. These represent
/// actual rendered output rather than further composition.
///
/// ### Conforming to Node
///
/// Implement `body` to describe the node's content using `@NodeBuilder`:
///
/// ```swift
/// struct Greeting: Node {
///     let name: String
///
///     var body: some Node {
///         TextNode("Hello, \(name)!")
///     }
/// }
/// ```
///
/// ### Primitive Nodes
///
/// Types that produce output directly (rather than composing other nodes)
/// set `Body` to `Never` and should never have their `body` accessed at
/// runtime. Score's renderer identifies these types by their concrete type
/// rather than calling `body`.
///
/// - Note: All conforming types must also conform to `Sendable` so that
///   node trees can be safely passed across concurrency boundaries.
public protocol Node: Sendable {

    /// The type of node that represents the body of this node.
    ///
    /// For composite nodes this is typically an opaque `some Node` type
    /// inferred from the return value of `body`. For primitive nodes —
    /// those that are rendered directly without further composition — this
    /// is `Never`.
    associatedtype Body: Node

    /// The content and structure of this node.
    ///
    /// Score calls this property when traversing the node tree. Do not
    /// call it directly. Primitive node types set `Body` to `Never` and
    /// trap unconditionally if `body` is accessed.
    ///
    /// Use `@NodeBuilder` to compose multiple child nodes in the body:
    ///
    /// ```swift
    /// var body: some Node {
    ///     HeaderNode()
    ///     ContentNode()
    ///     FooterNode()
    /// }
    /// ```
    @NodeBuilder
    var body: Body { get }
}

/// A node that renders nothing.
///
/// `EmptyNode` is Score's zero-content sentinel. It is produced by
/// `@NodeBuilder` when a builder block contains no statements, and can
/// also be used explicitly to satisfy a `Node` requirement without emitting
/// any output.
///
/// ### Example
///
/// ```swift
/// struct ConditionalBanner: Node {
///     let showBanner: Bool
///
///     var body: some Node {
///         if showBanner {
///             BannerNode(text: "Welcome back!")
///         }
///         // EmptyNode is produced automatically when showBanner is false
///     }
/// }
/// ```
///
/// - Note: `EmptyNode` is a primitive node — its `body` property is `Never`
///   and must never be called directly.
public struct EmptyNode: Node {

    /// The body of `EmptyNode`, which is never accessible at runtime.
    ///
    /// `EmptyNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }

    /// Creates an empty node that produces no rendered output.
    public init() {}
}

extension Node {
    /// Returns `true` when this node is a leaf (`Body == Never`) without
    /// evaluating `body`, which would trigger `fatalError` on leaf nodes.
    public var isLeafNode: Bool {
        Body.self == Never.self
    }
}

/// Conformance that allows `Never` to satisfy the `Node` associated-type
/// constraint used by primitive nodes.
///
/// Primitive nodes (e.g. `TextNode`, `EmptyNode`) declare `Body == Never`
/// to signal that they are rendered directly and do not have a composable
/// body. This extension provides the required `body` property, which traps
/// unconditionally if called — it should never be invoked by the renderer.
extension Never: Node {

    /// Accessing this property is a programming error and always traps.
    ///
    /// `Never` exists solely to satisfy the `Body` associated-type
    /// requirement for primitive nodes. The Score renderer identifies
    /// primitive nodes by their concrete type and never calls `body` on them.
    public var body: Never { fatalError() }
}

/// A node that renders a plain string of text.
///
/// `TextNode` is a primitive leaf node that emits text content into the
/// rendered output. It is the Score equivalent of a text run and maps to
/// a bare text node in HTML output.
///
/// `@NodeBuilder` automatically lifts `String` literals into `TextNode`
/// values, so you rarely need to construct one explicitly:
///
/// ```swift
/// struct Label: Node {
///     var body: some Node {
///         "Hello, world!"   // Becomes TextNode("Hello, world!")
///     }
/// }
/// ```
///
/// ### Example
///
/// ```swift
/// let node = TextNode("Score makes UI composition easy.")
/// ```
///
/// - Note: `TextNode` is a primitive node — its `body` property is `Never`
///   and must never be called directly.
public struct TextNode: Node {

    /// The raw string content that will be emitted into the rendered output.
    ///
    /// This value is passed verbatim to the renderer. Escaping or encoding
    /// (e.g. HTML entity encoding) is the responsibility of the renderer,
    /// not this type.
    public let content: String

    /// Creates a text node with the given string content.
    ///
    /// - Parameter content: The text string to render.
    public init(_ content: String) {
        self.content = content
    }

    /// The body of `TextNode`, which is never accessible at runtime.
    ///
    /// `TextNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}

/// A node that groups a fixed-size, heterogeneous collection of child nodes.
///
/// `TupleNode` is produced by `@NodeBuilder` when a builder block contains
/// multiple sibling nodes of different types. It preserves full static type
/// information about each child via Swift's parameter pack generics, enabling
/// renderers to dispatch on the concrete type of every child without type
/// erasure.
///
/// You do not typically create `TupleNode` values directly — `@NodeBuilder`
/// produces them automatically:
///
/// ```swift
/// struct Card: Node {
///     var body: some Node {
///         HeaderNode(title: "Score")   // \
///         BodyNode(text: "Hello!")     //  > TupleNode<HeaderNode, BodyNode, FooterNode>
///         FooterNode()                 // /
///     }
/// }
/// ```
///
/// - Note: `TupleNode` is a primitive node — its `body` property is `Never`
///   and must never be called directly.
public struct TupleNode<each Child: Node>: Node {

    /// The packed tuple of child nodes.
    ///
    /// Each element corresponds to one node passed into the builder block,
    /// preserving its exact concrete type. Renderers iterate this value
    /// using `repeat each children` to visit every child.
    public let children: (repeat each Child)

    /// Creates a tuple node wrapping the provided variadic child nodes.
    ///
    /// This initializer is called by `NodeBuilder.buildBlock` and is not
    /// typically invoked directly.
    ///
    /// - Parameter children: A variadic pack of child nodes to group together.
    public init(_ children: repeat each Child) {
        self.children = (repeat each children)
    }

    /// The body of `TupleNode`, which is never accessible at runtime.
    ///
    /// `TupleNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}

/// A node that represents the result of an `if`/`else` expression in a
/// `@NodeBuilder` block.
///
/// `ConditionalNode` is produced automatically by `@NodeBuilder` when a
/// builder block contains an `if`/`else` branch. It wraps either the true
/// branch (`TrueContent`) or the false branch (`FalseContent`) in its
/// `storage`, allowing renderers to inspect which branch is active and
/// dispatch accordingly — all without erasing the concrete child types.
///
/// You do not construct `ConditionalNode` directly. The following builder
/// block produces one implicitly:
///
/// ```swift
/// struct Banner: Node {
///     let isLoggedIn: Bool
///
///     var body: some Node {
///         if isLoggedIn {
///             WelcomeNode()       // TrueContent
///         } else {
///             LoginPromptNode()   // FalseContent
///         }
///     }
/// }
/// ```
///
/// - Note: `ConditionalNode` is a primitive node — its `body` property is
///   `Never` and must never be called directly.
public struct ConditionalNode<TrueContent: Node, FalseContent: Node>: Node {

    /// The underlying storage that holds whichever branch is currently active.
    ///
    /// Score renderers switch over this value to determine which child to
    /// render, preserving full static type information for both branches.
    public enum Storage: Sendable {

        /// The true branch of the conditional is active.
        ///
        /// This case is produced when the `if` condition evaluates to `true`.
        case first(TrueContent)

        /// The false branch of the conditional is active.
        ///
        /// This case is produced when the `if` condition evaluates to `false`,
        /// corresponding to the `else` clause of the builder block.
        case second(FalseContent)
    }

    /// The active branch of this conditional node.
    ///
    /// Inspect this value to determine whether the true or false branch
    /// should be rendered.
    public let storage: Storage

    /// The body of `ConditionalNode`, which is never accessible at runtime.
    ///
    /// `ConditionalNode` is a primitive node. Accessing `body` triggers a
    /// fatal error and is only declared to satisfy the `Node` protocol
    /// requirement.
    public var body: Never { fatalError() }
}

/// A node that wraps an optional child, rendering nothing when the child
/// is absent.
///
/// `OptionalNode` is produced by `@NodeBuilder` when a builder block
/// contains a standalone `if` statement without a corresponding `else`
/// clause. It holds either a concrete child node or `nil`, allowing
/// renderers to skip output entirely when no content is present.
///
/// You typically encounter `OptionalNode` as an implementation detail of
/// `@NodeBuilder` rather than constructing it yourself:
///
/// ```swift
/// struct Tooltip: Node {
///     let message: String?
///
///     var body: some Node {
///         if let message {
///             TextNode(message)   // Wrapped in OptionalNode
///         }
///     }
/// }
/// ```
///
/// - Note: `OptionalNode` is a primitive node — its `body` property is
///   `Never` and must never be called directly.
public struct OptionalNode<Wrapped: Node>: Node {

    /// The child node, or `nil` if the optional condition was false.
    ///
    /// When `nil`, the renderer should produce no output for this node.
    /// When non-`nil`, the renderer should recursively process `wrapped`.
    public let wrapped: Wrapped?

    /// Creates an optional node wrapping the given child.
    ///
    /// - Parameter wrapped: The child node to wrap, or `nil` to represent
    ///   the absence of content.
    public init(_ wrapped: Wrapped?) {
        self.wrapped = wrapped
    }

    /// The body of `OptionalNode`, which is never accessible at runtime.
    ///
    /// `OptionalNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}

/// A node that renders a dynamic collection of identically-typed child nodes.
///
/// `ForEachNode` is the Score equivalent of `ForEach` in SwiftUI. It holds
/// a `RandomAccessCollection` of data and a closure that maps each element
/// to a child node. Renderers iterate `data`, call `content` for each
/// element, and render the resulting nodes in order.
///
/// Use `ForEachNode` (or its `@NodeBuilder` counterpart) when the number of
/// children is determined at runtime:
///
/// ```swift
/// struct ProductList: Node {
///     let products: [Product]
///
///     var body: some Node {
///         ForEachNode(products) { product in
///             ProductRowNode(product: product)
///         }
///     }
/// }
/// ```
///
/// - Note: `ForEachNode` is a primitive node — its `body` property is
///   `Never` and must never be called directly.
public struct ForEachNode<Data: RandomAccessCollection, Content: Node>: Node where Data: Sendable, Data.Element: Sendable {

    /// The collection of data items used to drive content generation.
    ///
    /// The renderer iterates this collection in order and calls `content`
    /// for each element to produce the corresponding child node.
    public let data: Data

    /// A closure that maps a single data element to its corresponding node.
    ///
    /// This closure is called once per element in `data` during rendering.
    /// It must be `Sendable` so the node tree can be used across concurrency
    /// boundaries safely.
    public let content: @Sendable (Data.Element) -> Content

    /// Creates a `ForEachNode` from a collection and a content closure.
    ///
    /// - Parameters:
    ///   - data: The collection of items to render.
    ///   - content: A closure that maps each element in `data` to a child
    ///     node. The closure is marked `@NodeBuilder` so you can compose
    ///     multiple nodes for a single element.
    public init(_ data: Data, @NodeBuilder content: @escaping @Sendable (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

    /// The body of `ForEachNode`, which is never accessible at runtime.
    ///
    /// `ForEachNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}

/// A node that holds a homogeneous, runtime-sized array of child nodes.
///
/// `ArrayNode` is produced by `@NodeBuilder` when a builder block contains
/// a `for` loop or when `NodeBuilder.buildArray` is called directly. Unlike
/// `TupleNode` — which encodes child types statically — `ArrayNode` stores
/// children in a plain Swift array, so all elements must share the same
/// concrete `Node` type.
///
/// You do not typically construct `ArrayNode` directly. The following
/// builder block produces one automatically:
///
/// ```swift
/// struct TagList: Node {
///     let tags: [String]
///
///     var body: some Node {
///         for tag in tags {
///             TagNode(label: tag)
///         }
///     }
/// }
/// ```
///
/// For dynamic collections of data it is often more ergonomic to use
/// `ForEachNode`, which accepts any `RandomAccessCollection`.
///
/// - Note: `ArrayNode` is a primitive node — its `body` property is `Never`
///   and must never be called directly.
public struct ArrayNode<Element: Node>: Node {

    /// The ordered array of child nodes.
    ///
    /// Renderers iterate this array in order to produce output for each
    /// child. All elements share the same concrete `Element` type.
    public let children: [Element]

    /// The body of `ArrayNode`, which is never accessible at runtime.
    ///
    /// `ArrayNode` is a primitive node. Accessing `body` triggers a fatal
    /// error and is only declared to satisfy the `Node` protocol requirement.
    public var body: Never { fatalError() }
}
