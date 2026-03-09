/// A modifier that applies accessibility semantics to a node.
///
/// `AccessibilityModifier` allows a node to expose additional information
/// to assistive technologies such as screen readers, switch control,
/// and other accessibility tools.
///
/// This modifier does **not** affect visual rendering. Instead, it
/// augments the accessibility tree generated from the node hierarchy.
///
/// Typical uses include:
/// - Providing descriptive labels for non-text content
/// - Hiding purely decorative elements from assistive technologies
/// - Declaring semantic roles for improved navigation
///
/// ### Example
///
/// ```swift
/// Image(src: "profile.jpg", alt: "")
///     .accessibility(label: "User profile picture")
/// ```
///
/// ### Accessibility Mapping
///
/// Implementations typically map values to platform equivalents:
///
/// - Web: `aria-label`, `aria-hidden`, `role`
/// - Apple platforms: `accessibilityLabel`, `accessibilityHidden`,
///   and accessibility traits.
///
/// - Important: Only provide values that differ from visible content.
///   Redundant accessibility metadata can degrade screen reader usability.
public struct AccessibilityModifier: ModifierValue {

    /// A localized description announced by assistive technologies.
    ///
    /// Use this when the visible content does not adequately describe
    /// the element’s purpose.
    ///
    /// If `nil`, the system attempts to derive a label automatically
    /// from the node's content.
    public let label: String?

    /// Indicates whether the element should be hidden from
    /// assistive technologies.
    ///
    /// Set this to `true` for decorative or redundant elements
    /// that should not be navigable by screen readers.
    ///
    /// This does not affect visual visibility.
    public let isHidden: Bool?

    /// Declares the semantic role of the element.
    ///
    /// Roles help assistive technologies understand how users
    /// can interact with an element.
    ///
    /// Examples include:
    /// - `"button"`
    /// - `"navigation"`
    /// - `"heading"`
    ///
    /// Role interpretation is platform dependent.
    public let role: String?

    /// Creates an accessibility modifier.
    ///
    /// - Parameters:
    ///   - label: Optional accessibility description.
    ///   - isHidden: Whether the element is excluded from accessibility tools.
    ///   - role: Optional semantic role identifier.
    public init(
        label: String? = nil,
        isHidden: Bool? = nil,
        role: String? = nil
    ) {
        self.label = label
        self.isHidden = isHidden
        self.role = role
    }
}

extension Node {

    /// Applies accessibility semantics to this node.
    ///
    /// Use this modifier to expose additional information to assistive technologies
    /// such as screen readers without affecting the visual layout of the node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Image(src: "profile.jpg", alt: "")
    ///     .accessibility(label: "User profile picture")
    ///
    /// Divider()
    ///     .accessibility(hidden: true)
    ///
    /// Stack {
    ///     Link(to: "/") { "Home" }
    /// }
    /// .accessibility(role: "navigation")
    /// ```
    ///
    /// - Parameters:
    ///   - label: A localized description announced by assistive technologies. When `nil`,
    ///     the system derives a label from the node's visible content.
    ///   - hidden: When `true`, the element is excluded from the accessibility tree.
    ///     Defaults to `nil`.
    ///   - role: A semantic role identifier such as `"button"` or `"navigation"`.
    ///     When `nil`, the role is inferred from the element type.
    /// - Returns: A `ModifiedNode` with the accessibility modifier applied.
    public func accessibility(
        label: String? = nil,
        hidden isHidden: Bool? = nil,
        role: String? = nil
    ) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [AccessibilityModifier(label: label, isHidden: isHidden, role: role)])
    }
}
