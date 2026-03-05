import ScoreCore

/// A navigation control for moving between pages of content.
///
/// `Pagination` renders a `<nav>` with accessible labelling that
/// contains numbered page links and optional previous/next controls.
///
/// ### Example
///
/// ```swift
/// Pagination(
///     currentPage: 3,
///     totalPages: 10,
///     baseURL: "/articles"
/// )
/// ```
public struct Pagination: Component {

    /// The 1-based index of the current page.
    public let currentPage: Int

    /// The total number of pages.
    public let totalPages: Int

    /// The base URL used to construct page links (e.g. `"/articles"`).
    ///
    /// Page numbers are appended as a query parameter: `?page=N`.
    public let baseURL: String

    /// Creates a pagination control.
    ///
    /// - Parameters:
    ///   - currentPage: The currently active page number (1-based).
    ///   - totalPages: The total number of available pages.
    ///   - baseURL: The base URL for page links.
    public init(currentPage: Int, totalPages: Int, baseURL: String) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.baseURL = baseURL
    }

    public var body: some Node {
        Navigation {
            UnorderedList {
                if currentPage > 1 {
                    ListItem {
                        Link(to: "\(baseURL)?page=\(currentPage - 1)") {
                            Text(verbatim: "Previous")
                        }
                    }
                    .htmlAttribute("data-part", "prev")
                } else {
                    ListItem {
                        Text(verbatim: "Previous")
                    }
                    .htmlAttribute("data-part", "prev")
                    .htmlAttribute("data-state", "disabled")
                }
                ForEachNode(totalPages >= 1 ? Array(1...totalPages) : []) { page in
                    ListItem {
                        if page == currentPage {
                            Text(verbatim: "\(page)")
                        } else {
                            Link(to: "\(baseURL)?page=\(page)") {
                                Text(verbatim: "\(page)")
                            }
                        }
                    }
                    .htmlAttribute("data-part", "page")
                    .htmlAttribute("data-state", page == currentPage ? "active" : "inactive")
                }
                if currentPage < totalPages {
                    ListItem {
                        Link(to: "\(baseURL)?page=\(currentPage + 1)") {
                            Text(verbatim: "Next")
                        }
                    }
                    .htmlAttribute("data-part", "next")
                } else {
                    ListItem {
                        Text(verbatim: "Next")
                    }
                    .htmlAttribute("data-part", "next")
                    .htmlAttribute("data-state", "disabled")
                }
            }
        }
        .htmlAttribute("data-component", "pagination")
        .accessibility(label: "Pagination")
    }
}
