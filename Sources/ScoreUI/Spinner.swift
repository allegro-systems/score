import ScoreCSS
import ScoreCore
import ScoreHTML
import ScoreRuntime

/// A collection of Unicode Braille spinner frame sequences.
///
/// Each pattern defines a looping sequence of Unicode Braille characters
/// (U+2800–U+28FF) that creates a distinct loading animation when cycled
/// through with CSS or JavaScript.
///
/// ```swift
/// Spinner(.dots)       // ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
/// Spinner(.bounce)     // ⠁ ⠂ ⠄ ⠂
/// Spinner(.orbit)      // ⠈ ⠐ ⠠ ⢀ ⡀ ⠄ ⠂ ⠁
/// ```
public struct SpinnerPattern: Sendable, Hashable {

    /// The ordered sequence of Unicode Braille characters for one animation cycle.
    public let frames: [Character]

    /// A short identifier used in CSS class/keyframe names.
    public let name: String

    /// Creates a custom spinner pattern.
    ///
    /// - Parameters:
    ///   - name: A short identifier for CSS naming.
    ///   - frames: The Braille characters forming one animation cycle.
    public init(name: String, frames: [Character]) {
        self.name = name
        self.frames = frames
    }

    /// A rotating dot pattern. `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`
    public static let dots = SpinnerPattern(
        name: "dots",
        frames: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    )

    /// A vertical bounce pattern. `⠁ ⠂ ⠄ ⠂`
    public static let bounce = SpinnerPattern(
        name: "bounce",
        frames: ["⠁", "⠂", "⠄", "⠂"]
    )

    /// An orbiting dot pattern. `⠈ ⠐ ⠠ ⢀ ⡀ ⠄ ⠂ ⠁`
    public static let orbit = SpinnerPattern(
        name: "orbit",
        frames: ["⠈", "⠐", "⠠", "⢀", "⡀", "⠄", "⠂", "⠁"]
    )

    /// A growing bar pattern. `⠀ ⠁ ⠃ ⠇ ⡇ ⣇ ⣧ ⣷ ⣿`
    public static let bar = SpinnerPattern(
        name: "bar",
        frames: ["⠀", "⠁", "⠃", "⠇", "⡇", "⣇", "⣧", "⣷", "⣿"]
    )

    /// A wave-like sweep pattern. `⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈`
    public static let wave = SpinnerPattern(
        name: "wave",
        frames: ["⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈"]
    )

    /// A pulsing fill/empty pattern. `⣀ ⣤ ⣶ ⣿ ⣶ ⣤ ⣀ ⠀`
    public static let pulse = SpinnerPattern(
        name: "pulse",
        frames: ["⣀", "⣤", "⣶", "⣿", "⣶", "⣤", "⣀", "⠀"]
    )

    /// A clockwise rotation pattern. `⡈ ⠔ ⠢ ⢁`
    public static let clock = SpinnerPattern(
        name: "clock",
        frames: ["⡈", "⠔", "⠢", "⢁"]
    )

    /// A snake-like winding pattern. `⠏ ⠛ ⠹ ⢸ ⣰ ⣤ ⣆ ⡇`
    public static let snake = SpinnerPattern(
        name: "snake",
        frames: ["⠏", "⠛", "⠹", "⢸", "⣰", "⣤", "⣆", "⡇"]
    )

    /// A toggle between two states. `⠉ ⠛ ⣛ ⣿ ⣶ ⣤ ⣀ ⠀`
    public static let toggle = SpinnerPattern(
        name: "toggle",
        frames: ["⠉", "⠛", "⣛", "⣿", "⣶", "⣤", "⣀", "⠀"]
    )

    /// All built-in spinner patterns.
    public static let allPatterns: [SpinnerPattern] = [
        .dots, .bounce, .orbit, .bar, .wave, .pulse, .clock, .snake, .toggle,
    ]
}

/// A Unicode Braille spinner component for indicating loading state.
///
/// `Spinner` renders a CSS-animated Braille character sequence that cycles
/// through frames using `@keyframes` and the `content` property on a
/// `::after` pseudo-element. No JavaScript is required.
///
/// The spinner is accessible by default, rendering an `aria-label` of
/// "Loading" and `role="status"` for screen readers.
///
/// ```swift
/// Spinner()                          // Default dots pattern
/// Spinner(.orbit)                    // Orbiting dot
/// Spinner(.bar, label: "Saving…")    // Custom accessible label
/// ```
public struct Spinner: Node, SourceLocatable {

    /// The animation pattern to use.
    public let pattern: SpinnerPattern

    /// The accessible label announced by screen readers.
    public let label: String

    public let sourceLocation: SourceLocation

    /// Creates a spinner with the given pattern and accessible label.
    ///
    /// - Parameters:
    ///   - pattern: The Braille animation pattern. Defaults to `.dots`.
    ///   - label: The accessible label for screen readers. Defaults to `"Loading"`.
    ///   - file: The source file (supplied automatically by the compiler).
    ///   - filePath: The full source path (supplied automatically by the compiler).
    ///   - line: The source line (supplied automatically by the compiler).
    ///   - column: The source column (supplied automatically by the compiler).
    public init(
        _ pattern: SpinnerPattern = .dots,
        label: String = "Loading",
        file: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        self.pattern = pattern
        self.label = label
        self.sourceLocation = SourceLocation(
            fileID: file, filePath: filePath, line: line, column: column
        )
    }

    public var body: Never { fatalError() }
}

// MARK: - HTML Rendering

extension Spinner: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderHTML(merging: [], into: &output, renderer: renderer)
    }
}

extension Spinner: HTMLAttributeInjectable {
    package func renderHTML(
        merging extraAttributes: [(String, String)],
        into output: inout String,
        renderer: HTMLRenderer
    ) {
        var attrs: [(String, String)] = [
            ("data-spinner", pattern.name),
            ("role", "status"),
            ("aria-label", label),
        ]
        for (name, value) in extraAttributes {
            if name == "class", let index = attrs.firstIndex(where: { $0.0 == "class" }) {
                attrs[index].1 += " \(value)"
            } else {
                attrs.append((name, value))
            }
        }
        if renderer.isDevMode {
            attrs.append(("data-source", "\(sourceLocation.fileID):\(sourceLocation.line):\(sourceLocation.column)"))
            attrs.append(("data-source-path", "\(sourceLocation.filePath):\(sourceLocation.line):\(sourceLocation.column)"))
        }

        output.append("<span")
        for (name, value) in attrs {
            output.append(" \(name)=\"\(value)\"")
        }
        output.append("></span>")
    }
}

// MARK: - CSS Walking

extension Spinner: CSSWalkable {
    package var htmlTag: String? { "span" }

    package func walkChildren(collector: inout CSSCollector) {
        // No children to walk.
    }
}
