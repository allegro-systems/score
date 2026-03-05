import ScoreCore

/// The display size of an ``Avatar``.
///
/// Avatar sizes provide a consistent set of dimensions that align
/// with the Score design system.
public enum AvatarSize: String, Sendable {

    /// A small avatar, suitable for dense lists. Typically 32px.
    case small

    /// The default avatar size. Typically 40px.
    case medium

    /// A large avatar for profile headers. Typically 64px.
    case large
}

/// A circular image representing a user or entity.
///
/// `Avatar` displays a user's profile image with accessible alt text
/// and an optional fallback shown when the image is unavailable.
/// The fallback can be any node content, or a simple string via the
/// convenience initializer.
///
/// ### Example
///
/// ```swift
/// Avatar(src: "/avatars/alice.png", alt: "Alice", fallback: "AL")
///
/// Avatar(src: "/avatars/bob.png", alt: "Bob") {
///     Strong { Text(verbatim: "B") }
/// }
/// ```
public struct Avatar<Fallback: Node>: Component {

    /// The URL of the avatar image.
    public let src: String

    /// A short accessible description of the avatar.
    public let alt: String

    /// The node content displayed when the image cannot load.
    public let fallback: Fallback

    /// The display size of the avatar.
    public let size: AvatarSize

    /// Creates an avatar with custom fallback content.
    ///
    /// - Parameters:
    ///   - src: The image URL.
    ///   - alt: Accessible alternative text.
    ///   - size: The display size. Defaults to `.medium`.
    ///   - fallback: A `@NodeBuilder` closure producing fallback content.
    public init(
        src: String,
        alt: String,
        size: AvatarSize = .medium,
        @NodeBuilder fallback: () -> Fallback
    ) {
        self.src = src
        self.alt = alt
        self.size = size
        self.fallback = fallback()
    }

    public var body: some Node {
        Stack {
            Image(src: src, alt: alt)
                .htmlAttribute("data-part", "image")
            Stack {
                fallback
            }
            .htmlAttribute("data-part", "fallback")
        }
        .htmlAttribute("data-component", "avatar")
        .htmlAttribute("data-size", size.rawValue)
    }
}

extension Avatar where Fallback == OptionalNode<TextNode> {

    /// Creates an avatar with an optional text fallback such as initials.
    ///
    /// - Parameters:
    ///   - src: The image URL.
    ///   - alt: Accessible alternative text.
    ///   - fallback: Optional text shown when the image is unavailable.
    ///   - size: The display size. Defaults to `.medium`.
    public init(
        src: String,
        alt: String,
        fallback: String? = nil,
        size: AvatarSize = .medium
    ) {
        self.src = src
        self.alt = alt
        self.size = size
        if let fallback {
            self.fallback = OptionalNode(TextNode(fallback))
        } else {
            self.fallback = OptionalNode(nil)
        }
    }
}
