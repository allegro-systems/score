/// A type that can provide one or more pages to an application.
///
/// Both individual ``Page`` conformances and collection types like
/// `ContentPages` conform to this protocol, enabling a uniform
/// builder syntax in `Application.pages`.
public protocol PageProvider: Sendable {

    /// The pages provided by this value.
    var pages: [any Page] { get }
}

// Every Page is a single-element PageProvider.
extension Page {

    public var pages: [any Page] { [self] }
}

/// A result builder that collects pages and page providers into a flat array.
///
/// Use `@PageBuilder` on `Application.pages` to mix individual pages and
/// collection types like `ContentPages` in a declarative list:
///
/// ```swift
/// @PageBuilder
/// var pages: [any Page] {
///     HomePage()
///     AboutPage()
///     ContentPages("Content/docs", prefix: "/docs") { item in
///         DocsLayout { MarkdownNode(item.body) }
///     }
/// }
/// ```
@resultBuilder
public struct PageBuilder {

    public static func buildExpression(_ page: any Page) -> [any Page] {
        [page]
    }

    public static func buildExpression(_ provider: any PageProvider) -> [any Page] {
        provider.pages
    }

    public static func buildBlock(_ components: [any Page]...) -> [any Page] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any Page]?) -> [any Page] {
        component ?? []
    }

    public static func buildEither(first component: [any Page]) -> [any Page] {
        component
    }

    public static func buildEither(second component: [any Page]) -> [any Page] {
        component
    }

    public static func buildArray(_ components: [[any Page]]) -> [any Page] {
        components.flatMap { $0 }
    }
}
