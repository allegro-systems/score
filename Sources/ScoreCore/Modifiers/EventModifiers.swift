/// A DOM event type that can be bound to a client-side handler.
///
/// `DOMEvent` enumerates the standard browser events that Score supports
/// for client-side interactivity. Each case maps directly to its
/// corresponding JavaScript event name.
///
/// ### CSS Mapping
///
/// `DOMEvent` does not produce CSS — it is consumed by the ``JSEmitter``
/// to attach `addEventListener` calls in the emitted client script.
public struct DOMEvent: Sendable, Hashable {

    /// The JavaScript event name (e.g. `"click"`, `"input"`).
    public let name: String

    /// Creates a DOM event with the given JavaScript event name.
    ///
    /// - Parameter name: The event name as used by `addEventListener`.
    public init(_ name: String) {
        self.name = name
    }

    /// A mouse click or tap event.
    public static let click = DOMEvent("click")

    /// Fires when the value of an `<input>`, `<select>`, or `<textarea>`
    /// changes as the user types.
    public static let input = DOMEvent("input")

    /// Fires when the value of an `<input>`, `<select>`, or `<textarea>`
    /// is committed (e.g. on blur or Enter).
    public static let change = DOMEvent("change")

    /// A form submission event.
    public static let submit = DOMEvent("submit")

    /// A key-down event on the element.
    public static let keydown = DOMEvent("keydown")

    /// A key-up event on the element.
    public static let keyup = DOMEvent("keyup")

    /// The element has received focus.
    public static let focus = DOMEvent("focus")

    /// The element has lost focus.
    public static let blur = DOMEvent("blur")

    /// A drag operation has started on the element.
    public static let dragstart = DOMEvent("dragstart")

    /// The element is being dragged.
    public static let drag = DOMEvent("drag")

    /// A drag operation has ended.
    public static let dragend = DOMEvent("dragend")

    /// A dragged element has entered a valid drop target.
    public static let dragenter = DOMEvent("dragenter")

    /// A dragged element is over a valid drop target.
    public static let dragover = DOMEvent("dragover")

    /// A dragged element has left a valid drop target.
    public static let dragleave = DOMEvent("dragleave")

    /// An element is dropped on a valid drop target.
    public static let drop = DOMEvent("drop")
}

/// A modifier that binds a DOM event to a named handler function.
///
/// `EventBindingModifier` stores the event type and the name of the action
/// method to invoke when the event fires. The ``JSEmitter`` reads these
/// modifiers to emit `addEventListener` calls in the client script.
///
/// ### Example
///
/// ```swift
/// Button("Save")
///     .on(.click, action: "handleSave")
/// ```
///
/// ### CSS Mapping
///
/// This modifier does not produce CSS declarations.
public struct EventBindingModifier: ModifierValue {

    /// The DOM event to listen for.
    public let event: DOMEvent

    /// The name of the action handler to invoke.
    ///
    /// This corresponds to an `@Action`-annotated property or a named
    /// function in the component scope.
    public let handler: String

    /// Creates an event binding modifier.
    ///
    /// - Parameters:
    ///   - event: The DOM event to listen for.
    ///   - handler: The name of the handler function.
    public init(event: DOMEvent, handler: String) {
        self.event = event
        self.handler = handler
    }
}

extension Node {

    /// Binds a DOM event on this node to a named handler function.
    ///
    /// When the page is rendered with client-side reactivity enabled, the
    /// ``JSEmitter`` emits an `addEventListener` call that invokes the
    /// named handler whenever the specified event fires on this element.
    ///
    /// ### Example
    ///
    /// ```swift
    /// Input(type: .text)
    ///     .on(.input, action: "updateSearch")
    /// ```
    ///
    /// - Parameters:
    ///   - event: The DOM event to listen for.
    ///   - handler: The name of the action handler to invoke.
    /// - Returns: A `ModifiedNode` with the event binding applied.
    public func on(_ event: DOMEvent, action handler: String) -> ModifiedNode<Self> {
        modifier(EventBindingModifier(event: event, handler: handler))
    }
}
