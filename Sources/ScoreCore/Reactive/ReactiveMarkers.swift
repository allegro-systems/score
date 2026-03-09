/// Marker protocol for detecting `@State` properties via `Mirror`.
///
/// `State` conforms to this protocol so that tools like `JSEmitter` and
/// `HTMLRenderer` can identify reactive state properties at runtime using
/// `Mirror.subjectType is any StateIdentifying.Type`.
///
/// The ``stateJSEffect`` property allows the emitter to extract the
/// JavaScript effect expression from a type-erased `State` value.
public protocol StateIdentifying {
    /// The JavaScript effect expression, or empty string if none.
    var stateJSEffect: String { get }
}
extension State: StateIdentifying {
    public var stateJSEffect: String { jsEffect }
}

/// Marker protocol for detecting `@Computed` properties via `Mirror`.
public protocol ComputedIdentifying {}
extension Computed: ComputedIdentifying {}

/// Marker protocol for detecting `@Binding` properties via `Mirror`.
public protocol BindingIdentifying {}
extension Binding: BindingIdentifying {}
