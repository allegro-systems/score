/// A property wrapper that declares a piece of mutable, reactive state.
///
/// `State` marks a stored property as a reactive signal. During server-side
/// rendering, `wrappedValue` returns the initial value so that the first
/// paint contains correct content. On the client, the Score compiler emits a
/// `Signal.State` that tracks reads and writes, allowing the reactive engine
/// to update only the DOM nodes that depend on the value.
///
/// When ``jsEffect`` is provided, the compiler also emits a
/// `Score.effect(() => { ... })` that runs whenever the signal changes,
/// allowing the component to update DOM attributes reactively.
///
/// ### Usage
///
/// ```swift
/// struct Toggle: Component {
///     @State(effect: "scope.dataset.state = isPressed.get() ? 'on' : 'off'")
///     var isPressed = false
///
///     @Action func toggle() {
///         isPressed.toggle()
///     }
///
///     var body: some Node {
///         Button { "Toggle" }
///             .on(.click, action: "toggle")
///             .dataAttribute("state", isPressed ? "on" : "off")
///     }
/// }
/// ```
///
/// - Note: `State` is `Sendable` when its `Value` type is `Sendable`, which
///   is required for all properties used within `Node` trees.
@propertyWrapper
public struct State<Value: Sendable>: Sendable {

    /// The underlying stored value.
    ///
    /// During server-side rendering this is the initial value provided at
    /// declaration. On the client the compiler replaces access with a
    /// `Signal.State` read.
    public var wrappedValue: Value

    /// A binding to this state property for passing to child components.
    ///
    /// Use `$property` syntax to obtain a ``Binding`` that lets children
    /// read and write this state value.
    ///
    /// During server-side rendering this returns a constant binding with the
    /// current value. On the client, the compiler wires it to the parent's
    /// `Signal.State` for two-way reactivity.
    public var projectedValue: Binding<Value> {
        let currentValue = wrappedValue
        return Binding(
            get: { currentValue },
            set: { _ in }
        )
    }

    /// A JavaScript expression emitted inside a `Score.effect()` call.
    ///
    /// The expression may reference the state signal by its property name
    /// (e.g. `isPressed.get()`) and the `scope` element to update DOM
    /// attributes reactively.
    public let jsEffect: String

    /// Creates a reactive state property with a DOM effect.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value for this state property.
    ///   - effect: A JavaScript expression run inside `Score.effect()`.
    public init(wrappedValue: Value, effect: String) {
        self.wrappedValue = wrappedValue
        self.jsEffect = effect
    }

    /// Creates a reactive state property with the given initial value.
    ///
    /// - Parameter wrappedValue: The initial value for this state property.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        self.jsEffect = ""
    }
}
