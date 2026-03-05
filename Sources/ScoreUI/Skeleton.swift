import ScoreCore

/// A placeholder loading indicator that mimics content layout.
///
/// `Skeleton` renders an empty block-level element styled with a
/// pulsing animation by the Score theme. Use it in place of real
/// content while data is loading.
///
/// ### Example
///
/// ```swift
/// Skeleton(width: "200px", height: "20px")
/// Skeleton(width: "100%", height: "120px")
/// ```
public struct Skeleton: Component {

    /// The CSS width of the skeleton placeholder.
    public let width: String

    /// The CSS height of the skeleton placeholder.
    public let height: String

    /// Creates a skeleton loading placeholder.
    ///
    /// - Parameters:
    ///   - width: The CSS width. Defaults to `"100%"`.
    ///   - height: The CSS height. Defaults to `"20px"`.
    public init(width: String = "100%", height: String = "20px") {
        self.width = width
        self.height = height
    }

    public var body: some Node {
        Stack {
            EmptyNode()
        }
        .htmlAttribute("data-component", "skeleton")
        .htmlAttribute("style", "width:\(width);height:\(height)")
        .accessibility(hidden: true)
    }
}
