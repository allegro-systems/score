/// A modifier that binds an element's visibility to a `@State` property.
///
/// When applied, the element is shown or hidden reactively based on the
/// state's boolean value. The ``JSEmitter`` emits a `Score.effect` that
/// toggles the element's `hidden` attribute.
///
/// ### CSS Mapping
///
/// This modifier does not produce CSS declarations. It adds a `data-r`
/// HTML attribute for the JSEmitter to target, and optionally the `hidden`
/// attribute for the initial server-rendered state.
public struct ReactiveVisibilityModifier: ModifierValue {

    /// The name of the boolean `@State` property controlling visibility.
    public let stateName: String

    /// Whether the element should be visible in the initial server render.
    public let initiallyVisible: Bool

    /// Creates a reactive visibility modifier.
    ///
    /// - Parameters:
    ///   - stateName: The name of the boolean state property.
    ///   - initiallyVisible: Whether the element starts visible. Defaults
    ///     to `false`, meaning the element renders with the `hidden`
    ///     attribute on the server.
    public init(stateName: String, initiallyVisible: Bool = false) {
        self.stateName = stateName
        self.initiallyVisible = initiallyVisible
    }
}

extension Node {

    /// Toggles this element's visibility based on a boolean state property.
    ///
    /// When the named state property is `true`, the element is visible;
    /// when `false`, the element is hidden via the HTML `hidden` attribute.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Stack { ... }
    ///     .visible(when: "isRevealed")
    /// ```
    ///
    /// - Parameters:
    ///   - stateName: The name of the boolean `@State` property.
    ///   - initially: Whether the element starts visible in the server
    ///     render. Defaults to `false`.
    /// - Returns: A `ModifiedNode` with the reactive visibility binding.
    public func visible(when stateName: String, initially: Bool = false) -> ModifiedNode<Self> {
        modifier(ReactiveVisibilityModifier(stateName: stateName, initiallyVisible: initially))
    }
}
