/// A node that represents the primary content area of a document.
///
/// `Main` renders as the HTML `<main>` element. It communicates to browsers and
/// assistive technologies that its children constitute the dominant, unique
/// content of the page — distinct from repeated elements such as headers,
/// footers, and navigation.
///
/// There should be only one `Main` node per rendered page.
///
/// ### Example
///
/// ```swift
/// Main {
///     Article {
///         Text("Welcome to Score")
///     }
/// }
/// ```
///
/// - Important: Do not nest `Main` inside another `Main`. Only one instance
///   should be present in the document at a time.
public struct Main<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the primary content of the document.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a main content container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that defines a thematic grouping of content within a document.
///
/// `Section` renders as the HTML `<section>` element. It is used to divide a
/// page into distinct, self-contained regions — each typically introduced by a
/// heading — such as chapters, tabbed content panels, or numbered sections of
/// a thesis.
///
/// ### Example
///
/// ```swift
/// Section {
///     Heading(.two) { "About Us" }
///     Text { "We build great things." }
/// }
/// ```
///
/// - Note: If the content could stand alone as an independent piece (such as a
///   blog post or news item), prefer `Article` instead.
public struct Section<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the body of this section.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a section container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that represents a self-contained piece of content.
///
/// `Article` renders as the HTML `<article>` element. It is intended for
/// content that is independently distributable or reusable — such as a blog
/// post, a news story, a forum post, or a product card.
///
/// ### Example
///
/// ```swift
/// Article {
///     Heading(.two) { "Swift 6 Released" }
///     Text { "Apple announced Swift 6 with strict concurrency checking..." }
/// }
/// ```
///
/// - Note: An `Article` may contain multiple `Section` nodes to subdivide its
///   content further.
public struct Article<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the body of this article.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an article container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that represents an introductory or navigational header region.
///
/// `Header` renders as the HTML `<header>` element. It typically contains
/// introductory content for its nearest sectioning ancestor, such as a site
/// logo, a page title, or a top-level navigation bar. When used at the top
/// level of a page it is treated as the site-wide banner landmark by assistive
/// technologies.
///
/// ### Example
///
/// ```swift
/// Header {
///     Image(src: "logo.png", alt: "Logo")
///     Navigation {
///         Link(to: "/") { "Home" }
///         Link(to: "/about") { "About" }
///     }
/// }
/// ```
///
/// - Note: `Header` can appear multiple times in a document — once at the page
///   level and again inside each `Article` or `Section` that warrants its own
///   introduction.
public struct Header<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the header's introductory content.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a header container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that represents the footer region of its nearest sectioning ancestor.
///
/// `Footer` renders as the HTML `<footer>` element. It typically contains
/// metadata about its containing section, such as author information,
/// copyright notices, links to related documents, or contact details.
/// When placed at the outermost level of a page it is treated as the
/// `contentinfo` landmark by assistive technologies.
///
/// ### Example
///
/// ```swift
/// Footer {
///     Text { "\u{00A9} 2026 Score. All rights reserved." }
///     Link(to: "/privacy") { "Privacy Policy" }
/// }
/// ```
///
/// - Note: Like `Header`, a `Footer` may appear inside `Article` or `Section`
///   nodes in addition to the outermost page level.
public struct Footer<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the footer's content.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a footer container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that represents content tangentially related to the surrounding content.
///
/// `Aside` renders as the HTML `<aside>` element. It is appropriate for
/// sidebars, pull-quotes, advertising blocks, or groups of navigation links
/// that are considered separate from the primary content flow but still
/// contextually related to the page.
///
/// ### Example
///
/// ```swift
/// Aside {
///     Heading(.three) { "Related Articles" }
///     Link(to: "/concurrency") { "Swift Concurrency Deep Dive" }
/// }
/// ```
///
/// - Note: When an `Aside` appears at the top level of a page, assistive
///   technologies expose it as a `complementary` landmark.
public struct Aside<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the aside's tangential content.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates an aside container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A node that represents a section of navigation links.
///
/// `Navigation` renders as the HTML `<nav>` element. It is intended for major
/// navigation blocks — such as the site's primary menu, a table of contents,
/// or a breadcrumb trail — and is exposed as a `navigation` landmark to
/// assistive technologies.
///
/// ### Example
///
/// ```swift
/// Navigation {
///     Link(to: "/") { "Home" }
///     Link(to: "/blog") { "Blog" }
///     Link(to: "/contact") { "Contact" }
/// }
/// ```
///
/// - Note: Not every group of links needs to be wrapped in `Navigation`. Reserve
///   it for the major navigational blocks of a page to avoid cluttering the
///   landmark map presented to screen-reader users.
public struct Navigation<Content: Node>: Node, SourceLocatable {

    /// The child nodes that form the navigation links or structure.
    public let content: Content
    public let sourceLocation: SourceLocation

    /// Creates a navigation container with the given child content.
    public init(
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}

/// A transparent grouping node that produces no wrapper element in the rendered output.
///
/// `Group` is a purely structural tool that allows multiple nodes to be
/// combined and passed as a single `Node` value without introducing an
/// additional HTML element into the document. This is useful in conditional
/// or looping contexts inside a `@NodeBuilder` closure where you need to
/// return more than one node from a single branch.
///
/// ### Example
///
/// ```swift
/// Stack {
///     if isLoggedIn {
///         Group {
///             Text { "Welcome back!" }
///             Link(to: "/dashboard") { "Dashboard" }
///         }
///     }
/// }
/// ```
///
/// - Note: Unlike `Stack`, `Group` does not emit a wrapping `<div>`. Its
///   children are rendered as direct siblings of the surrounding content.
public struct Group<Content: Node>: Node {

    /// The child nodes contained within this group.
    public let content: Content

    /// Creates a transparent group with the given child content.
    ///
    /// - Parameter content: A node builder closure that produces the children to be
    ///     rendered as a flat sequence of siblings with no enclosing element.
    public init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
