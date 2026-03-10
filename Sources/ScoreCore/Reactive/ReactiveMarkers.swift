/// Marker protocol for detecting `@State` descriptors via `Mirror`.
///
/// `StateDescriptor` conforms to this protocol so that the
/// ``JSEmitter`` can identify reactive state properties at runtime.
public protocol StateIdentifying {}
extension StateDescriptor: StateIdentifying {}

/// Marker protocol for detecting `@Computed` descriptors via `Mirror`.
///
/// `ComputedDescriptor` conforms to this protocol so that the
/// ``JSEmitter`` can identify computed properties at runtime.
public protocol ComputedIdentifying {}
extension ComputedDescriptor: ComputedIdentifying {}

/// Marker protocol for detecting `@Binding` properties via `Mirror`.
public protocol BindingIdentifying {}
extension Binding: BindingIdentifying {}
