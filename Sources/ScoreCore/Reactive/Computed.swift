/// A property wrapper that declares a derived, reactive value.
///
/// `Computed` marks a read-only property as a derived signal. During
/// server-side rendering, `wrappedValue` evaluates the closure immediately
/// and returns its result. On the client, the Score compiler emits a
/// `Signal.Computed` that automatically re-evaluates when any upstream
/// `State` signals it depends on change.
///
/// ### Usage
///
/// ```swift
/// struct PriceDisplay: Component {
///     @State var price = 10.0
///     @State var quantity = 1
///
///     @Computed var total: Double { price * Double(quantity) }
///
///     var body: some Node {
///         Text { "Total: \(total)" }
///     }
/// }
/// ```
///
/// - Note: The closure must be `Sendable` to satisfy Swift 6 concurrency
///   requirements within `Node` trees.
@propertyWrapper
public struct Computed<Value: Sendable>: Sendable {

    private let compute: @Sendable () -> Value

    /// The derived value, computed by evaluating the closure.
    ///
    /// During server-side rendering the closure runs synchronously to
    /// produce the initial value. On the client the compiler replaces access
    /// with a `Signal.Computed` read that auto-tracks dependencies.
    public var wrappedValue: Value {
        compute()
    }

    /// Creates a computed property with the given derivation closure.
    ///
    /// - Parameter wrappedValue: An autoclosure that produces the derived
    ///   value. Evaluated eagerly during SSR; lazily tracked on the client.
    public init(wrappedValue: @autoclosure @escaping @Sendable () -> Value) {
        self.compute = wrappedValue
    }
}
