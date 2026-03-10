/// A type-safe CSS transform function.
///
/// `Transform` represents individual CSS transform functions that can be
/// composed together. Use the enum cases to create transform values, then
/// pass one or more to the `.transform()` modifier.
///
/// ### Example
///
/// ```swift
/// Icon()
///     .transform(.rotate(45))
///
/// Badge()
///     .transform(.translate(x: -50, y: -50), .scale(1.1))
/// ```
///
/// ### CSS Mapping
///
/// Each value maps to a CSS transform function within the `transform` property.
public enum Transform: Sendable, Hashable {
    /// Rotates the element by the given angle in degrees.
    ///
    /// - Parameter degrees: The rotation angle in degrees.
    case rotate(Double)

    /// Scales the element uniformly.
    ///
    /// - Parameter factor: The scale factor where `1.0` is unchanged.
    case scale(Double)

    /// Scales the element independently along each axis.
    ///
    /// - Parameters:
    ///   - x: The horizontal scale factor.
    ///   - y: The vertical scale factor.
    case scaleXY(x: Double, y: Double)

    /// Translates the element along both axes.
    ///
    /// - Parameters:
    ///   - x: The horizontal offset in pixels.
    ///   - y: The vertical offset in pixels.
    case translate(x: Double, y: Double)

    /// Translates the element along the horizontal axis.
    ///
    /// - Parameter pixels: The horizontal offset in pixels.
    case translateX(Double)

    /// Translates the element along the vertical axis.
    ///
    /// - Parameter pixels: The vertical offset in pixels.
    case translateY(Double)

    /// Skews the element along the horizontal axis.
    ///
    /// - Parameter degrees: The skew angle in degrees.
    case skewX(Double)

    /// Skews the element along the vertical axis.
    ///
    /// - Parameter degrees: The skew angle in degrees.
    case skewY(Double)

    /// The CSS string representation of this transform function.
    public var cssValue: String {
        switch self {
        case .rotate(let v): "rotate(\(v)deg)"
        case .scale(let v): "scale(\(v))"
        case .scaleXY(let x, let y): "scale(\(x), \(y))"
        case .translate(let x, let y): "translate(\(x)px, \(y)px)"
        case .translateX(let v): "translateX(\(v)px)"
        case .translateY(let v): "translateY(\(v)px)"
        case .skewX(let v): "skewX(\(v)deg)"
        case .skewY(let v): "skewY(\(v)deg)"
        }
    }
}

/// A modifier that applies one or more CSS transforms to a node.
///
/// ### Example
///
/// ```swift
/// Icon()
///     .transform(.rotate(45))
///
/// Badge()
///     .transform(.translate(x: -50, y: -50), .scale(1.1))
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `transform` property on the rendered element.
public struct TransformModifier: ModifierValue {
    /// The transform functions to apply, in order.
    public let transforms: [Transform]

    /// Creates a transform modifier with the given transform functions.
    ///
    /// - Parameter transforms: The CSS transform functions to apply.
    public init(_ transforms: [Transform]) {
        self.transforms = transforms
    }
}

/// The CSS easing function controlling the rate of change during an animation or transition.
///
/// ### CSS Mapping
///
/// Maps to CSS `transition-timing-function` or `animation-timing-function` values.
public enum TimingFunction: String, Sendable {
    /// A slow start and end with a faster middle. The browser default.
    ///
    /// CSS equivalent: `ease`.
    case ease

    /// A constant rate of change from start to finish.
    ///
    /// CSS equivalent: `linear`.
    case linear

    /// A slow start that accelerates toward the end.
    ///
    /// CSS equivalent: `ease-in`.
    case easeIn = "ease-in"

    /// A fast start that decelerates toward the end.
    ///
    /// CSS equivalent: `ease-out`.
    case easeOut = "ease-out"

    /// A slow start and slow end.
    ///
    /// CSS equivalent: `ease-in-out`.
    case easeInOut = "ease-in-out"
}

/// A CSS property that can be targeted by a transition.
///
/// `TransitionProperty` identifies which CSS property should be animated
/// when its value changes.
///
/// ### CSS Mapping
///
/// Maps to the CSS `transition-property` value.
public enum TransitionProperty: String, Sendable {
    /// Transitions all animatable properties.
    ///
    /// CSS equivalent: `transition-property: all`.
    case all

    /// Transitions the element's opacity.
    ///
    /// CSS equivalent: `transition-property: opacity`.
    case opacity

    /// Transitions the element's transform.
    ///
    /// CSS equivalent: `transition-property: transform`.
    case transform

    /// Transitions the element's background colour.
    ///
    /// CSS equivalent: `transition-property: background-color`.
    case backgroundColor = "background-color"

    /// Transitions the element's border colour.
    ///
    /// CSS equivalent: `transition-property: border-color`.
    case borderColor = "border-color"

    /// Transitions the element's text colour.
    ///
    /// CSS equivalent: `transition-property: color`.
    case color

    /// Transitions the element's width.
    ///
    /// CSS equivalent: `transition-property: width`.
    case width

    /// Transitions the element's height.
    ///
    /// CSS equivalent: `transition-property: height`.
    case height

    /// Transitions the element's box shadow.
    ///
    /// CSS equivalent: `transition-property: box-shadow`.
    case boxShadow = "box-shadow"

    /// Transitions the element's filter effects.
    ///
    /// CSS equivalent: `transition-property: filter`.
    case filter

    /// Transitions the element's margin.
    ///
    /// CSS equivalent: `transition-property: margin`.
    case margin

    /// Transitions the element's padding.
    ///
    /// CSS equivalent: `transition-property: padding`.
    case padding
}

/// A modifier that animates CSS property changes on a node over time.
///
/// ### Example
///
/// ```swift
/// Button("Hover me")
///     .transition(property: .backgroundColor, duration: 0.2, timing: .easeInOut)
///
/// Panel()
///     .transition(property: .opacity, duration: 0.3, timing: .easeOut, delay: 0.1)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `transition` shorthand property on the rendered element.
public struct TransitionModifier: ModifierValue {
    /// The CSS property to animate.
    public let property: TransitionProperty

    /// The duration of the transition animation in seconds.
    public let duration: Double

    /// The easing function for the transition.
    ///
    /// When `nil`, the browser's default easing (`ease`) is used.
    public let timing: TimingFunction?

    /// The delay in seconds before the transition begins.
    ///
    /// When `nil`, the transition starts immediately.
    public let delay: Double?

    /// Creates a transition modifier.
    ///
    /// - Parameters:
    ///   - property: The CSS property to animate.
    ///   - duration: The animation duration in seconds.
    ///   - timing: Optional easing function. Defaults to `nil`.
    ///   - delay: Optional delay in seconds. Defaults to `nil`.
    public init(property: TransitionProperty, duration: Double, timing: TimingFunction? = nil, delay: Double? = nil) {
        self.property = property
        self.duration = duration
        self.timing = timing
        self.delay = delay
    }
}

/// The direction in which a CSS keyframe animation plays.
///
/// ### CSS Mapping
///
/// Maps to the CSS `animation-direction` property.
public enum AnimationDirection: String, Sendable {
    /// The animation plays forward each cycle.
    ///
    /// CSS equivalent: `animation-direction: normal`.
    case normal

    /// The animation plays backward each cycle.
    ///
    /// CSS equivalent: `animation-direction: reverse`.
    case reverse

    /// The animation alternates between forward and backward on each cycle.
    ///
    /// CSS equivalent: `animation-direction: alternate`.
    case alternate

    /// The animation alternates, starting backward on the first cycle.
    ///
    /// CSS equivalent: `animation-direction: alternate-reverse`.
    case alternateReverse = "alternate-reverse"
}

/// How styles are applied before and after a CSS keyframe animation executes.
///
/// ### CSS Mapping
///
/// Maps to the CSS `animation-fill-mode` property.
public enum AnimationFillMode: String, Sendable {
    /// No styles are applied outside the animation's execution.
    ///
    /// CSS equivalent: `animation-fill-mode: none`.
    case none

    /// The element retains the styles of the last keyframe after the animation ends.
    ///
    /// CSS equivalent: `animation-fill-mode: forwards`.
    case forwards

    /// The element applies the styles of the first keyframe before the animation starts.
    ///
    /// CSS equivalent: `animation-fill-mode: backwards`.
    case backwards

    /// Combines `forwards` and `backwards` behaviour.
    ///
    /// CSS equivalent: `animation-fill-mode: both`.
    case both
}

/// How many times a CSS keyframe animation repeats.
///
/// ### CSS Mapping
///
/// Maps to the CSS `animation-iteration-count` property.
public struct AnimationIterationCount: Sendable {

    /// The CSS string representation of this iteration count.
    public let cssValue: String

    /// The animation repeats indefinitely.
    public static let infinite = AnimationIterationCount(cssValue: "infinite")

    /// The animation plays a specific number of times.
    ///
    /// - Parameter n: The number of times to play the animation.
    /// - Returns: An iteration count for the given number of cycles.
    public static func count(_ n: Int) -> AnimationIterationCount {
        AnimationIterationCount(cssValue: "\(n)")
    }
}

/// A modifier that plays a named CSS keyframe animation on a node.
///
/// ### Example
///
/// ```swift
/// Spinner()
///     .animation(name: "spin", duration: 1.0, timing: .linear, iterationCount: .infinite)
///
/// Toast()
///     .animation(name: "fadeIn", duration: 0.3, timing: .easeOut, fillMode: .forwards)
/// ```
///
/// ### CSS Mapping
///
/// Maps to the CSS `animation` shorthand property on the rendered element.
public struct AnimationModifier: ModifierValue {
    /// The name of the `@keyframes` animation to play.
    public let name: String

    /// The duration of one animation cycle in seconds.
    public let duration: Double

    /// The easing function for the animation.
    ///
    /// When `nil`, the browser's default easing (`ease`) is used.
    public let timing: TimingFunction?

    /// The delay in seconds before the animation begins.
    ///
    /// When `nil`, the animation starts immediately.
    public let delay: Double?

    /// How many times the animation repeats.
    ///
    /// When `nil`, the animation plays once.
    public let iterationCount: AnimationIterationCount?

    /// The direction in which the animation plays.
    ///
    /// When `nil`, the animation plays forward.
    public let direction: AnimationDirection?

    /// How styles are applied before and after the animation executes.
    ///
    /// When `nil`, no fill mode is applied.
    public let fillMode: AnimationFillMode?

    /// Creates an animation modifier.
    ///
    /// - Parameters:
    ///   - name: The `@keyframes` animation name.
    ///   - duration: The duration of one animation cycle in seconds.
    ///   - timing: Optional easing function. Defaults to `nil`.
    ///   - delay: Optional delay in seconds. Defaults to `nil`.
    ///   - iterationCount: Optional iteration count. Defaults to `nil`.
    ///   - direction: Optional playback direction. Defaults to `nil`.
    ///   - fillMode: Optional fill mode. Defaults to `nil`.
    public init(
        name: String, duration: Double, timing: TimingFunction? = nil, delay: Double? = nil,
        iterationCount: AnimationIterationCount? = nil, direction: AnimationDirection? = nil, fillMode: AnimationFillMode? = nil
    ) {
        self.name = name
        self.duration = duration
        self.timing = timing
        self.delay = delay
        self.iterationCount = iterationCount
        self.direction = direction
        self.fillMode = fillMode
    }
}

extension Node {
    /// Applies one or more CSS transforms to this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Icon()
    ///     .transform(.rotate(45))
    ///
    /// Tooltip()
    ///     .transform(.translate(x: -50, y: -100))
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `transform` property on the rendered element.
    ///
    /// - Parameter transforms: The CSS transform functions to apply.
    /// - Returns: A `ModifiedNode` with the transform modifier applied.
    public func transform(_ transforms: Transform...) -> ModifiedNode<Self> {
        ModifiedNode(content: self, modifiers: [TransformModifier(transforms)])
    }

    /// Animates changes to a CSS property on this node over time.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Button("Hover me")
    ///     .transition(property: .opacity, duration: 0.2, timing: .easeInOut)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `transition` shorthand property on the rendered element.
    ///
    /// - Parameters:
    ///   - property: The CSS property to animate.
    ///   - duration: The animation duration in seconds.
    ///   - timing: Optional easing function. Defaults to `nil`.
    ///   - delay: Optional delay in seconds. Defaults to `nil`.
    /// - Returns: A `ModifiedNode` with the transition modifier applied.
    public func transition(property: TransitionProperty, duration: Double, timing: TimingFunction? = nil, delay: Double? = nil) -> ModifiedNode<Self> {
        let mod = TransitionModifier(property: property, duration: duration, timing: timing, delay: delay)
        return ModifiedNode(content: self, modifiers: [mod])
    }

    /// Plays a named CSS keyframe animation on this node.
    ///
    /// ### Example
    ///
    /// ```swift
    /// LoadingSpinner()
    ///     .animation(name: "spin", duration: 1.0, timing: .linear, iterationCount: .infinite)
    /// ```
    ///
    /// ### CSS Mapping
    ///
    /// Maps to the CSS `animation` shorthand property on the rendered element.
    ///
    /// - Parameters:
    ///   - name: The `@keyframes` animation name.
    ///   - duration: The duration of one animation cycle in seconds.
    ///   - timing: Optional easing function. Defaults to `nil`.
    ///   - delay: Optional delay in seconds. Defaults to `nil`.
    ///   - iterationCount: Optional iteration count. Defaults to `nil`.
    ///   - direction: Optional playback direction. Defaults to `nil`.
    ///   - fillMode: Optional fill mode. Defaults to `nil`.
    /// - Returns: A `ModifiedNode` with the animation modifier applied.
    public func animation(
        name: String, duration: Double, timing: TimingFunction? = nil, delay: Double? = nil,
        iterationCount: AnimationIterationCount? = nil, direction: AnimationDirection? = nil, fillMode: AnimationFillMode? = nil
    ) -> ModifiedNode<Self> {
        let mod = AnimationModifier(
            name: name, duration: duration, timing: timing, delay: delay,
            iterationCount: iterationCount, direction: direction, fillMode: fillMode
        )
        return ModifiedNode(content: self, modifiers: [mod])
    }
}
