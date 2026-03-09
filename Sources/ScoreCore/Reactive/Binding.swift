/// A property wrapper that creates a two-way reference to a parent
/// component's `@State` property.
///
/// `Binding` enables child components to read and write a value owned by
/// a parent. The parent passes its state's projected value (`$property`)
/// and the child declares the property as `@Binding`.
///
/// During server-side rendering the binding reads its initial value
/// directly. On the client, mutations flow back to the parent's
/// `Signal.State` through the setter.
///
/// ### Usage
///
/// ```swift
/// // Parent owns the state
/// struct Parent: Component {
///     @State var count: Int = 0
///
///     var body: some Node {
///         Stepper(count: $count)
///     }
/// }
///
/// // Child receives a binding
/// struct Stepper: Component {
///     @Binding var count: Int
///
///     var body: some Node {
///         Stack {
///             Button { "-" }.on(.click, action: "decrement")
///             Text { "\(count)" }
///             Button { "+" }.on(.click, action: "increment")
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct Binding<Value: Sendable>: Sendable {

    private let get: @Sendable () -> Value
    private let set: @Sendable (Value) -> Void

    /// The current value of the binding.
    ///
    /// Reading returns the parent's current state value. Writing
    /// updates the parent's state, triggering reactive updates.
    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    /// The binding itself, for passing to child components.
    public var projectedValue: Binding<Value> { self }

    /// Creates a binding with explicit getter and setter closures.
    ///
    /// - Parameters:
    ///   - get: A closure that reads the current value.
    ///   - set: A closure that writes a new value.
    public init(
        get: @escaping @Sendable () -> Value,
        set: @escaping @Sendable (Value) -> Void
    ) {
        self.get = get
        self.set = set
    }

    /// Creates a constant binding that always returns the given value.
    ///
    /// Useful for previews and static contexts where no mutation is needed.
    ///
    /// - Parameter value: The constant value.
    /// - Returns: A binding that returns `value` and ignores writes.
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}
