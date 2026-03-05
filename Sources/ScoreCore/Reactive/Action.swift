/// A property wrapper that marks a closure as a client-side action.
///
/// `Action` identifies a closure that should be emitted as a JavaScript
/// function on the client. The ``jsBody`` string is emitted verbatim as
/// the function body, allowing it to call `.set()` / `.get()` on signals
/// created from `@State` declarations.
///
/// During server-side rendering the wrapped Swift closure is inert — it
/// exists only to satisfy the type system. The real implementation lives
/// in the ``jsBody`` string emitted to the client.
///
/// ### Usage
///
/// ```swift
/// struct Counter: Component {
///     @State var count = 0
///     @Action(js: "count.set(count.get() + 1)") var increment = {}
///
///     var body: some Node {
///         Button { Text(verbatim: "\(count)") }
///             .on(.click, "increment")
///     }
/// }
/// ```
///
/// - Note: The closure must be `Sendable` to satisfy Swift 6 concurrency
///   requirements.
@propertyWrapper
public struct Action: Sendable {

    /// The action closure.
    ///
    /// During server-side rendering this closure is never invoked. On the
    /// client the compiler emits an equivalent JavaScript function.
    public var wrappedValue: @Sendable () -> Void

    /// The JavaScript function body emitted on the client.
    ///
    /// When non-empty, this string is placed inside `function name() { ... }`
    /// in the emitted script. It may reference state signals by their
    /// Swift property name (e.g. `count.set(count.get() + 1)`).
    public let jsBody: String

    /// Creates an action with an empty JavaScript body.
    ///
    /// Use this form for actions whose behavior is handled entirely by
    /// external JS (e.g. the editor runtime) rather than emitted signals.
    ///
    /// - Parameter wrappedValue: The inert Swift closure (typically `{}`).
    public init(wrappedValue: @escaping @Sendable () -> Void) {
        self.wrappedValue = wrappedValue
        self.jsBody = ""
    }

    /// Creates an action with an explicit JavaScript body.
    ///
    /// Usage: `@Action(js: "count.set(count.get() + 1)") var increment = {}`
    ///
    /// - Parameters:
    ///   - wrappedValue: The inert Swift closure (typically `{}`).
    ///   - js: The JavaScript code emitted as the function body.
    public init(wrappedValue: @escaping @Sendable () -> Void, js: String) {
        self.wrappedValue = wrappedValue
        self.jsBody = js
    }
}
