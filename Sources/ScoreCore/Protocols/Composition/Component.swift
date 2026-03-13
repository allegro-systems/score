/// A protocol that marks a type as a reusable, composable UI building block.
///
/// `Component` refines `Node` to represent self-contained pieces of user
/// interface that encapsulate their own structure, layout, and styling.
/// Components are the primary abstraction for building modular, reusable UI
/// in Score.
///
/// Components may be purely structural or they may own instance-scoped
/// reactive state via `@State`, `@Computed`, and `@Action` property wrappers.
/// When a component declares state, the compiler emits a factory function
/// (`mountComponentName(el, props)`) that creates instance-scoped signals and
/// returns a teardown handle. State is never shared between instances.
///
/// ### Three-Level Scope Model (ADR-007)
///
/// | Protocol      | Scope            | JS Pattern                |
/// |---------------|------------------|---------------------------|
/// | `Application` | Global singleton | `export const` in app.js  |
/// | `Page`        | Module-scoped    | `const` in page module    |
/// | `Component`   | Instance-scoped  | `const` inside factory fn |
///
/// ### Example
///
/// ```swift
/// // Stateless component — pure structure and styling
/// struct UserCard: Component {
///     let username: String
///     let avatarURL: String
///
///     var body: some Node {
///         Stack {
///             Image(src: avatarURL, alt: username)
///             Text(username)
///         }
///         .flex(direction: .row)
///     }
/// }
///
/// // Stateful component — instance-scoped signals
/// struct QuantityPicker: Component {
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
/// ### Protocol Conformance Requirements
///
/// A type conforming to `Component` must:
/// - Implement `var body: Body { get }` (inherited from `Node`), where `Body`
///   is any concrete `Node` type, typically expressed as `some Node`.
/// - Satisfy `Sendable` (inherited transitively through `Node`).
///
/// - Note: Stateful component state is torn down on unmount. Each instance is
///   fully isolated — no shared state between mounts.
public protocol Component: Node {
    /// An optional key used to merge multiple instances into a single
    /// shared scope.  When `nil` (the default), every instance gets its
    /// own independent state.  Override with a fixed string to share
    /// state across all instances that use the same key — useful for
    /// singletons like a theme toggle that appears in both desktop and
    /// mobile navigation.
    static var scopeKey: String? { get }
}

extension Component {
    public static var scopeKey: String? { nil }
}

/// Marks a struct as a `Component` and generates an initializer when needed.
///
/// Apply `@Component` to a struct to automatically add `Component` protocol
/// conformance. If the struct declares a `content: Content` stored property,
/// the macro also generates an `init` with a `@NodeBuilder` trailing-closure
/// parameter for composing child nodes:
///
/// ```swift
/// @Component
/// struct Card {
///     let content: Content
///
///     var body: some Node {
///         Article { content }
///     }
/// }
///
/// // Usage — trailing-closure syntax:
/// Card {
///     Heading(.two) { "Hello" }
///     Paragraph { "World" }
/// }
/// ```
///
/// Structs without a `content: Content` property receive only the conformance:
///
/// ```swift
/// @Component
/// struct Badge {
///     let label: String
///     var body: some Node { Text { label } }
/// }
/// ```
@attached(member, names: named(init))
@attached(extension, conformances: Component)
public macro Component() = #externalMacro(module: "ScoreMacros", type: "ComponentMacro")
