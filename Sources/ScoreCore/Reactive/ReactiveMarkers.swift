/// Internal marker protocol for detecting `@State` properties via `Mirror`.
///
/// `State` conforms to this protocol so that tools like `JSEmitter` and
/// `HTMLRenderer` can identify reactive state properties at runtime using
/// `Mirror.subjectType is any _StateMarker.Type`.
///
/// The ``stateJSEffect`` property allows the emitter to extract the
/// JavaScript effect expression from a type-erased `State` value.
public protocol _StateMarker {
    /// The JavaScript effect expression, or empty string if none.
    var stateJSEffect: String { get }
}
extension State: _StateMarker {
    public var stateJSEffect: String { jsEffect }
}

/// Internal marker protocol for detecting `@Computed` properties via `Mirror`.
public protocol _ComputedMarker {}
extension Computed: _ComputedMarker {}

/// Internal marker protocol for detecting `@Binding` properties via `Mirror`.
public protocol _BindingMarker {}
extension Binding: _BindingMarker {}
