/// A node that displays the completion progress of a task.
///
/// `Progress` renders as the HTML `<progress>` element. It communicates how
/// much of an operation has been completed — for example, a file upload, a
/// multi-step form, or a background calculation. When `value` is omitted the
/// progress bar is shown in an indeterminate state, signalling that an
/// operation is in progress but its completion percentage is unknown.
///
/// Typical uses include:
/// - Showing upload or download progress during a file transfer
/// - Indicating step completion in a multi-step onboarding wizard
/// - Reflecting background processing where duration is known
///
/// ### Example
///
/// ```swift
/// // Determinate — 70 % complete
/// Progress(value: 70, max: 100)
///
/// // Indeterminate — completion unknown
/// Progress()
/// ```
///
/// - Important: Provide fallback text between the opening and closing tags for
///   browsers that do not support the `<progress>` element. Assistive
///   technologies use `value` and `max` to compute and announce a percentage,
///   so always supply both when the completion amount is known.
public struct Progress: Node, SourceLocatable {

    /// The current amount of work that has been completed.
    ///
    /// Rendered as the HTML `value` attribute. Must be between `0` and `max`
    /// when provided. If `nil`, the progress bar is rendered in an indeterminate
    /// state.
    public let value: Double?

    /// The total amount of work required for the task to be considered complete.
    ///
    /// Rendered as the HTML `max` attribute. Defaults to `1.0` in the browser
    /// when omitted. If `nil`, the browser uses its default maximum.
    public let max: Double?

    public let sourceLocation: SourceLocation

    /// Creates a progress indicator.
    public init(value: Double? = nil, max: Double? = nil, file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        self.value = value
        self.max = max
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}

/// A node that represents a scalar measurement within a known range.
///
/// `Meter` renders as the HTML `<meter>` element. Unlike ``Progress``, it
/// conveys a static measurement rather than the completion of a task — such as
/// disk usage, a relevance score, or a temperature reading. Browsers visually
/// colour the bar to reflect whether the value falls in a low, medium, or high
/// range relative to the `optimum`.
///
/// Typical uses include:
/// - Displaying disk or memory usage as a fraction of total capacity
/// - Showing a relevance or match score for a search result
/// - Indicating battery level or signal strength
///
/// ### Example
///
/// ```swift
/// // Disk usage: 7.5 GB of 10 GB used
/// Meter(value: 7.5, min: 0, max: 10, low: 2, high: 8, optimum: 1)
///
/// // Password strength score out of 100
/// Meter(value: 72, max: 100)
/// ```
///
/// - Important: Do not use `Meter` to indicate task progress; use ``Progress``
///   instead. `Meter` is intended for measurements whose ranges have meaningful
///   semantic interpretations (low, high, optimum).
public struct Meter: Node, SourceLocatable {

    /// The current numeric measurement being represented.
    ///
    /// Rendered as the HTML `value` attribute. Must fall between `min` and
    /// `max`.
    public let value: Double

    /// The lower bound of the measured range.
    ///
    /// Rendered as the HTML `min` attribute. Defaults to `0` in the browser
    /// when omitted. If `nil`, the browser uses its default minimum.
    public let min: Double?

    /// The upper bound of the measured range.
    ///
    /// Rendered as the HTML `max` attribute. Defaults to `1` in the browser
    /// when omitted. If `nil`, the browser uses its default maximum.
    public let max: Double?

    /// The upper threshold below which the value is considered low.
    ///
    /// Rendered as the HTML `low` attribute. Values at or below this threshold
    /// may be styled differently by the browser to indicate a suboptimal
    /// reading.
    public let low: Double?

    /// The lower threshold above which the value is considered high.
    ///
    /// Rendered as the HTML `high` attribute. Values at or above this threshold
    /// may be styled differently by the browser.
    public let high: Double?

    /// The value within the range that is considered most favourable.
    ///
    /// Rendered as the HTML `optimum` attribute. The browser uses this in
    /// combination with `low` and `high` to determine the semantic "goodness"
    /// of the current `value` and may colour the meter accordingly.
    public let optimum: Double?

    public let sourceLocation: SourceLocation

    /// Creates a scalar measurement gauge.
    public init(
        value: Double,
        min: Double? = nil,
        max: Double? = nil,
        low: Double? = nil,
        high: Double? = nil,
        optimum: Double? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column
    ) {
        self.value = value
        self.min = min
        self.max = max
        self.low = low
        self.high = high
        self.optimum = optimum
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
    }

    public var body: Never { fatalError() }
}
