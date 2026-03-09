/// A protocol for instance-scoped components with isolated state.
///
/// `Element` represents a component whose `@State` properties create
/// instance-scoped signals. Each mount of an Element gets its own
/// isolated signal graph — state is never shared between instances.
///
/// The compiler emits a factory function for each Element
/// (`mountElementName(el, props)`) that creates instance-scoped
/// signals and returns a teardown handle.
///
/// ### Three-Level Scope Model (ADR-007)
///
/// | Protocol      | Scope            | JS Pattern                |
/// |---------------|------------------|---------------------------|
/// | `Application` | Global singleton | `export const` in app.js  |
/// | `Page`        | Module-scoped    | `const` in page module    |
/// | `Element`     | Instance-scoped  | `const` inside factory fn |
///
/// ### Example
///
/// ```swift
/// struct QuantityPicker: Element {
///     let product: Product
///     let max: Int = 10
///
///     @State var count: Int = 0
///
///     @Computed var canIncrement: Bool { count < max }
///
///     @Action func increment() {
///         guard canIncrement else { return }
///         count += 1
///     }
///
///     @Action func decrement() {
///         guard count > 0 else { return }
///         count -= 1
///     }
/// }
/// ```
///
/// - Note: Element state is torn down on unmount. Each instance is
///   fully isolated — no shared state between mounts.
public protocol Element: Node {}
