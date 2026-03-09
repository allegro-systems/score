/// A node that renders a bullet-point list of items with no implied order.
///
/// `UnorderedList` renders as the HTML `<ul>` element. Use it when the items
/// belong together as a group but their sequence does not carry meaning —
/// such as a list of features, a set of navigation links, or a collection of
/// tags.
///
/// Each item inside the list should be wrapped in a ``ListItem`` node.
///
/// ### Example
///
/// ```swift
/// UnorderedList {
///     ListItem { "Swift" }
///     ListItem { "Xcode" }
///     ListItem { "SwiftUI" }
/// }
/// ```
public struct UnorderedList<Content: Node>: Node {

    /// The ``ListItem`` children that make up the list's entries.
    public let content: Content

    /// Creates an unordered (bulleted) list.
    ///
    /// - Parameter content: A node builder closure providing ``ListItem`` children.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a sequentially numbered list of items.
///
/// `OrderedList` renders as the HTML `<ol>` element. Use it when the order
/// of items is meaningful — such as step-by-step instructions, a ranked
/// chart, or a numbered outline.
///
/// Typical uses include:
/// - Recipe instructions or assembly steps
/// - Top-10 rankings or leaderboards
/// - Numbered legal or contractual clauses
///
/// ### Example
///
/// ```swift
/// OrderedList {
///     ListItem { "Preheat oven to 180 °C" }
///     ListItem { "Mix flour and sugar" }
///     ListItem { "Bake for 25 minutes" }
/// }
///
/// // Counting down from 5
/// OrderedList(start: 5, reversed: true) {
///     ListItem { "Five" }
///     ListItem { "Four" }
///     ListItem { "Three" }
/// }
/// ```
public struct OrderedList<Content: Node>: Node {

    /// The integer value at which the list numbering begins.
    ///
    /// Rendered as the HTML `start` attribute. If `nil`, numbering starts at
    /// `1` (the browser default).
    public let start: Int?

    /// Whether the list counts downward from `start` (or from the number of
    /// items) instead of upward.
    ///
    /// When `true`, renders the HTML `reversed` attribute.
    public let isReversed: Bool

    /// The ``ListItem`` children that make up the numbered entries.
    public let content: Content

    /// Creates an ordered (numbered) list.
    ///
    /// - Parameters:
    ///   - start: The starting number for the list. Defaults to `nil` (starts
    ///     at 1).
    ///   - isReversed: When `true`, numbers descend rather than ascend.
    ///     Defaults to `false`.
    ///   - content: A node builder closure providing ``ListItem`` children.
    public init(start: Int? = nil, isReversed: Bool = false, @NodeBuilder content: () -> Content) {
        self.start = start
        self.isReversed = isReversed
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that represents a single item within an ``UnorderedList`` or
/// ``OrderedList``.
///
/// `ListItem` renders as the HTML `<li>` element. It can contain inline text,
/// images, links, or even nested lists to create hierarchical structures.
///
/// ### Example
///
/// ```swift
/// UnorderedList {
///     ListItem { "First item" }
///     ListItem {
///         "Second item with a "
///         Link(to: "/details") { "link" }
///     }
///     ListItem {
///         "Nested list:"
///         UnorderedList {
///             ListItem { "Sub-item A" }
///             ListItem { "Sub-item B" }
///         }
///     }
/// }
/// ```
public struct ListItem<Content: Node>: Node {

    /// The content displayed inside the list item.
    public let content: Content

    /// Creates a list item.
    ///
    /// - Parameter content: A node builder closure providing the item's content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders a list of term–description pairs.
///
/// `DescriptionList` renders as the HTML `<dl>` element. Each entry in the
/// list is composed of one or more ``DescriptionTerm`` nodes followed by one
/// or more ``DescriptionDetails`` nodes that provide the corresponding
/// definitions or values.
///
/// Typical uses include:
/// - Glossaries that pair vocabulary terms with their definitions
/// - Metadata panels showing key–value pairs (e.g. Author, Published, Tags)
/// - FAQ sections where questions are terms and answers are details
///
/// ### Example
///
/// ```swift
/// DescriptionList {
///     DescriptionTerm { "Author" }
///     DescriptionDetails { "Jane Doe" }
///
///     DescriptionTerm { "Published" }
///     DescriptionDetails { "2024-01-15" }
/// }
/// ```
public struct DescriptionList<Content: Node>: Node {

    /// The ``DescriptionTerm`` and ``DescriptionDetails`` children that form
    /// the term–description pairs.
    public let content: Content

    /// Creates a description list.
    ///
    /// - Parameter content: A node builder closure providing alternating
    ///     ``DescriptionTerm`` and ``DescriptionDetails`` children.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders the term part of a term–description pair inside a
/// ``DescriptionList``.
///
/// `DescriptionTerm` renders as the HTML `<dt>` element. It should be
/// followed by one or more ``DescriptionDetails`` siblings that provide the
/// definition or value for this term.
///
/// ### Example
///
/// ```swift
/// DescriptionList {
///     DescriptionTerm { "Framework" }
///     DescriptionDetails { "Score" }
/// }
/// ```
public struct DescriptionTerm<Content: Node>: Node {

    /// The term or label content rendered inside the `<dt>` element.
    public let content: Content

    /// Creates a description term.
    ///
    /// - Parameter content: A node builder closure providing the term's text or inline
    ///     content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}

/// A node that renders the description or definition part of a term–description
/// pair inside a ``DescriptionList``.
///
/// `DescriptionDetails` renders as the HTML `<dd>` element. It provides the
/// value, definition, or elaboration that corresponds to the preceding
/// ``DescriptionTerm``.
///
/// ### Example
///
/// ```swift
/// DescriptionList {
///     DescriptionTerm { "Language" }
///     DescriptionDetails { "Swift" }
///
///     DescriptionTerm { "Platform" }
///     DescriptionDetails { "macOS" }
///     DescriptionDetails { "Linux" }
/// }
/// ```
public struct DescriptionDetails<Content: Node>: Node {

    /// The definition or value content rendered inside the `<dd>` element.
    public let content: Content

    /// Creates a description details node.
    ///
    /// - Parameter content: A node builder closure providing the description's text or
    ///     inline content.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }
}
