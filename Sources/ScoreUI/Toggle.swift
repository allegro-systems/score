import ScoreCore

/// A pressable toggle button that alternates between on and off states.
///
/// `Toggle` renders as a `<button>` with reactive state managed by the
/// Score runtime. Clicking the button toggles `isPressed` and updates
/// `data-state` and `aria-pressed` accordingly.
///
/// Unlike ``SwitchToggle``, which uses a checkbox, `Toggle` is a
/// stateful button suitable for toolbar actions and mode switches.
///
/// ### Example
///
/// ```swift
/// Toggle(label: "Bold", isPressed: true)
/// Toggle(label: "Italic")
/// ```
public struct Toggle: Component {

    /// The visible label for the toggle button.
    public let label: String

    /// Whether the toggle is in the pressed (on) state.
    @State public var isPressed: Bool

    /// Whether the toggle is disabled.
    public let isDisabled: Bool

    /// Toggles the pressed state.
    @Action(js: "isPressed.set(!isPressed.get())")
    public var toggle = {}

    /// Creates a toggle button.
    ///
    /// - Parameters:
    ///   - label: The button label text.
    ///   - isPressed: Whether the toggle starts pressed. Defaults to `false`.
    ///   - disabled: Whether the toggle is disabled. Defaults to `false`.
    public init(
        label: String,
        isPressed: Bool = false,
        disabled: Bool = false
    ) {
        self.label = label
        self._isPressed = State(
            wrappedValue: isPressed,
            effect: "scope.dataset.state = isPressed.get() ? 'on' : 'off'"
        )
        self.isDisabled = disabled
    }

    public var body: some Node {
        Button(disabled: isDisabled) {
            Text(verbatim: label)
        }
        .on(.click, "toggle")
        .htmlAttribute("data-component", "toggle")
        .htmlAttribute("data-state", isPressed ? "on" : "off")
        .accessibility(role: "button")
    }
}
