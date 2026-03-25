/// A predefined animation with sane defaults for common use cases.
///
/// `AnimationPreset` bundles a `@keyframes` definition with recommended
/// duration, timing, and fill mode so that animations can be applied in a
/// single call without manual CSS authoring.
///
/// ### Example
///
/// ```swift
/// Heading { "Welcome" }
///     .animate(.fadeIn)
///
/// Stack { content }
///     .animate(.slideUp, duration: 0.5, delay: 0.2)
///
/// // Multiple animations on one element:
/// Card()
///     .animate([.fadeIn, .slideUp])
/// ```
public enum AnimationPreset: String, Sendable, CaseIterable {
    case fadeIn
    case fadeOut
    case slideUp
    case slideDown
    case slideLeft
    case slideRight
    case scaleIn
    case scaleOut
    case bounce
    case pulse
    case spin

    /// The CSS `@keyframes` name for this preset.
    public var keyframesName: String { "score-\(rawValue)" }

    /// The default duration in seconds.
    public var defaultDuration: Double {
        switch self {
        case .fadeIn, .fadeOut: 0.3
        case .slideUp, .slideDown, .slideLeft, .slideRight: 0.4
        case .scaleIn, .scaleOut: 0.3
        case .bounce: 0.6
        case .pulse: 1.5
        case .spin: 1.0
        }
    }

    /// The default timing function.
    public var defaultTiming: TimingFunction {
        switch self {
        case .fadeIn, .fadeOut, .scaleIn, .scaleOut: .easeOut
        case .slideUp, .slideDown, .slideLeft, .slideRight: .easeOut
        case .bounce: .easeOut
        case .pulse: .easeInOut
        case .spin: .linear
        }
    }

    /// The default fill mode.
    public var defaultFillMode: AnimationFillMode {
        switch self {
        case .spin, .pulse: .none
        default: .both
        }
    }

    /// The default iteration count.
    public var defaultIterationCount: AnimationIterationCount? {
        switch self {
        case .spin, .pulse: .infinite
        default: nil
        }
    }

    /// The CSS `@keyframes` rule body for this preset.
    public var keyframesCSS: String {
        switch self {
        case .fadeIn:
            "from { opacity: 0 } to { opacity: 1 }"
        case .fadeOut:
            "from { opacity: 1 } to { opacity: 0 }"
        case .slideUp:
            "from { opacity: 0; transform: translateY(20px) } to { opacity: 1; transform: translateY(0) }"
        case .slideDown:
            "from { opacity: 0; transform: translateY(-20px) } to { opacity: 1; transform: translateY(0) }"
        case .slideLeft:
            "from { opacity: 0; transform: translateX(20px) } to { opacity: 1; transform: translateX(0) }"
        case .slideRight:
            "from { opacity: 0; transform: translateX(-20px) } to { opacity: 1; transform: translateX(0) }"
        case .scaleIn:
            "from { opacity: 0; transform: scale(0.9) } to { opacity: 1; transform: scale(1) }"
        case .scaleOut:
            "from { opacity: 1; transform: scale(1) } to { opacity: 0; transform: scale(0.9) }"
        case .bounce:
            "0% { transform: translateY(0) } 40% { transform: translateY(-15px) } 60% { transform: translateY(-7px) } 80% { transform: translateY(-3px) } 100% { transform: translateY(0) }"
        case .pulse:
            "0%, 100% { opacity: 1 } 50% { opacity: 0.5 }"
        case .spin:
            "from { transform: rotate(0deg) } to { transform: rotate(360deg) }"
        }
    }
}

/// A single animation entry within a `PresetAnimationModifier`.
///
/// Each entry pairs a preset with optional overrides for duration, timing,
/// delay, iteration count, and fill mode.
public struct AnimationEntry: Sendable {

    /// The animation preset.
    public let preset: AnimationPreset

    /// Duration override in seconds. Uses the preset's default when `nil`.
    public let duration: Double?

    /// Timing function override.
    public let timing: TimingFunction?

    /// Delay in seconds before the animation starts.
    public let delay: Double?

    /// Iteration count override.
    public let iterationCount: AnimationIterationCount?

    /// Fill mode override.
    public let fillMode: AnimationFillMode?

    public init(
        preset: AnimationPreset,
        duration: Double? = nil,
        timing: TimingFunction? = nil,
        delay: Double? = nil,
        iterationCount: AnimationIterationCount? = nil,
        fillMode: AnimationFillMode? = nil
    ) {
        self.preset = preset
        self.duration = duration
        self.timing = timing
        self.delay = delay
        self.iterationCount = iterationCount
        self.fillMode = fillMode
    }
}

/// A modifier that applies one or more preset animations to a node.
///
/// When multiple animations are specified, they are emitted as a
/// comma-separated CSS `animation` shorthand, allowing them to play
/// simultaneously.
///
/// ### CSS Mapping
///
/// Maps to the CSS `animation` shorthand property and emits `@keyframes`
/// rules for each selected preset.
public struct PresetAnimationModifier: ModifierValue {

    /// The animation entries to apply.
    public let entries: [AnimationEntry]

    public init(entries: [AnimationEntry]) {
        self.entries = entries
    }

    /// Convenience initializer for a single animation.
    public init(
        preset: AnimationPreset,
        duration: Double? = nil,
        timing: TimingFunction? = nil,
        delay: Double? = nil,
        iterationCount: AnimationIterationCount? = nil,
        fillMode: AnimationFillMode? = nil
    ) {
        self.entries = [
            AnimationEntry(
                preset: preset,
                duration: duration,
                timing: timing,
                delay: delay,
                iterationCount: iterationCount,
                fillMode: fillMode
            )
        ]
    }
}

/// A modifier that triggers an animation when the element enters the viewport
/// using the Intersection Observer API.
///
/// ### Example
///
/// ```swift
/// FeatureCard()
///     .animateOnScroll(.fadeIn)
///
/// Section { content }
///     .animateOnScroll(.slideUp, threshold: 0.2, once: true)
///
/// // Multiple scroll-triggered animations:
/// Card()
///     .animateOnScroll([.fadeIn, .slideUp])
/// ```
public struct IntersectionObserverModifier: ModifierValue {

    /// The animation entries to play on intersection.
    public let entries: [AnimationEntry]

    /// The visibility threshold (0.0–1.0) at which to trigger.
    public let threshold: Double

    /// The root margin for the intersection observer.
    public let rootMargin: String

    /// Whether the animation should only trigger once.
    public let once: Bool

    public init(
        entries: [AnimationEntry],
        threshold: Double = 0.1,
        rootMargin: String = "0px",
        once: Bool = true
    ) {
        self.entries = entries
        self.threshold = threshold
        self.rootMargin = rootMargin
        self.once = once
    }

    /// Convenience initializer for a single animation.
    public init(
        preset: AnimationPreset,
        duration: Double? = nil,
        timing: TimingFunction? = nil,
        delay: Double? = nil,
        threshold: Double = 0.1,
        rootMargin: String = "0px",
        once: Bool = true
    ) {
        self.entries = [
            AnimationEntry(
                preset: preset,
                duration: duration,
                timing: timing,
                delay: delay
            )
        ]
        self.threshold = threshold
        self.rootMargin = rootMargin
        self.once = once
    }
}

extension Node {

    /// Applies one or more preset animations with sane defaults.
    ///
    /// ### Example
    ///
    /// ```swift
    /// // Single animation
    /// Heading { "Hello" }
    ///     .animate(.fadeIn)
    ///
    /// // Single animation with overrides
    /// Card()
    ///     .animate(.slideUp, duration: 0.5, delay: 0.1)
    ///
    /// // Multiple simultaneous animations
    /// Hero()
    ///     .animate(.fadeIn, .slideUp)
    /// ```
    public func animate(
        _ preset: AnimationPreset,
        duration: Double? = nil,
        timing: TimingFunction? = nil,
        delay: Double? = nil,
        iterationCount: AnimationIterationCount? = nil,
        fillMode: AnimationFillMode? = nil
    ) -> ModifiedNode<Self> {
        modifier(
            PresetAnimationModifier(
                preset: preset,
                duration: duration,
                timing: timing,
                delay: delay,
                iterationCount: iterationCount,
                fillMode: fillMode
            ))
    }

    /// Applies multiple preset animations simultaneously.
    ///
    /// All animations play at the same time, each with its preset's
    /// default duration, timing, and fill mode.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .animate([.fadeIn, .slideUp])
    ///
    /// Hero()
    ///     .animate([.fadeIn, .scaleIn, .slideUp])
    /// ```
    public func animate(_ presets: [AnimationPreset]) -> ModifiedNode<Self> {
        modifier(
            PresetAnimationModifier(
                entries: presets.map { AnimationEntry(preset: $0) }
            ))
    }

    /// Applies multiple animation entries with individual overrides.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .animate([
    ///         AnimationEntry(preset: .fadeIn, duration: 0.3),
    ///         AnimationEntry(preset: .slideUp, duration: 0.5, delay: 0.1),
    ///     ])
    /// ```
    public func animate(_ entries: [AnimationEntry]) -> ModifiedNode<Self> {
        modifier(PresetAnimationModifier(entries: entries))
    }

    /// Triggers one or more animations when the element scrolls into view.
    ///
    /// Uses the Intersection Observer API to detect when the element
    /// enters the viewport, then applies the specified animations.
    ///
    /// ### Example
    ///
    /// ```swift
    /// FeatureCard()
    ///     .animateOnScroll(.fadeIn)
    ///
    /// Section { content }
    ///     .animateOnScroll(.slideUp, threshold: 0.2, once: true)
    /// ```
    public func animateOnScroll(
        _ preset: AnimationPreset,
        duration: Double? = nil,
        timing: TimingFunction? = nil,
        delay: Double? = nil,
        threshold: Double = 0.1,
        rootMargin: String = "0px",
        once: Bool = true
    ) -> ModifiedNode<Self> {
        modifier(
            IntersectionObserverModifier(
                preset: preset,
                duration: duration,
                timing: timing,
                delay: delay,
                threshold: threshold,
                rootMargin: rootMargin,
                once: once
            ))
    }

    /// Triggers multiple animations simultaneously when the element scrolls into view.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Card()
    ///     .animateOnScroll([.fadeIn, .slideUp])
    /// ```
    public func animateOnScroll(
        _ presets: [AnimationPreset],
        threshold: Double = 0.1,
        rootMargin: String = "0px",
        once: Bool = true
    ) -> ModifiedNode<Self> {
        modifier(
            IntersectionObserverModifier(
                entries: presets.map { AnimationEntry(preset: $0) },
                threshold: threshold,
                rootMargin: rootMargin,
                once: once
            ))
    }
}
