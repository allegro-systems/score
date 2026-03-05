import Foundation
import ScoreCore
import ScoreHTML

/// Emits client-side JavaScript that wires reactive signals and event
/// listeners for a page and its stateful components.
///
/// `JSEmitter` inspects a page instance using `Mirror` to discover
/// `@State`, `@Computed`, and `@Action` property wrappers, and walks the
/// rendered node tree to find `EventBindingModifier` values and stateful
/// `Component` instances. It produces a `<script>` block that:
///
/// 1. Creates a `Score.state()` call per `@State` with its initial value
/// 2. Creates a `Score.computed()` call per `@Computed`
/// 3. Creates a plain function per `@Action`
/// 4. Attaches `addEventListener` calls per `EventBindingModifier`
/// 5. Wraps component-level state in scoped IIFEs
///
/// ### Three-Level State Hierarchy
///
/// - **Page-level**: State declared directly on a `Page` — global to the page
/// - **Component-level**: State declared on a `Component` — scoped via
///   `data-scope` and emitted in an IIFE
/// - **Global-level**: Application state (future — managed via stores)
///
/// ### Element Targeting
///
/// Reactive elements receive `data-s="N"` attributes in HTML (injected by
/// `HTMLRenderer`). Within component scopes, selectors are scoped:
/// `scope.querySelector('[data-s="N"]')`.
///
/// ### Example
///
/// ```swift
/// let script = JSEmitter.emit(page: myPage, environment: .development)
/// ```
public struct JSEmitter: Sendable {

    private init() {}

    /// The result of emitting a page script, including an optional source map.
    public struct EmitResult: Sendable {
        /// The `<script>` tag string, or empty if no reactivity is needed.
        public let script: String
        /// The v3 source map JSON, or `nil` if no script was emitted or in production.
        public let sourceMap: String?
        /// A stable identifier for this script (used as the source map filename).
        public let scriptID: String?
    }

    /// A discovered reactive state declaration.
    public struct StateDeclaration: Sendable {
        /// The property name in the Swift source.
        public let name: String
        /// A JSON-compatible string representation of the initial value.
        public let initialValue: String
        /// A JavaScript expression to run inside `Score.effect()`, or empty.
        public let jsEffect: String
    }

    /// A discovered computed property declaration.
    public struct ComputedDeclaration: Sendable {
        /// The property name in the Swift source.
        public let name: String
    }

    /// A discovered action declaration.
    public struct ActionDeclaration: Sendable {
        /// The property name in the Swift source.
        public let name: String
        /// The JavaScript function body. Empty if the action has no client logic.
        public let jsBody: String
    }

    /// A discovered event binding from the node tree.
    public struct EventBinding: Sendable {
        /// The zero-based index used for `data-s` targeting.
        public let elementIndex: Int
        /// The DOM event name (e.g. `"click"`).
        public let event: String
        /// The handler function name.
        public let handler: String
    }

    /// A discovered stateful component scope in the node tree.
    public struct ComponentScope: Sendable {
        /// The scope name (lowercase type name, e.g. "counter").
        public let name: String
        /// Reactive state declarations within this component.
        public let states: [StateDeclaration]
        /// Computed property declarations within this component.
        public let computeds: [ComputedDeclaration]
        /// Action declarations within this component.
        public let actions: [ActionDeclaration]
        /// Event bindings within this component's subtree.
        public let bindings: [EventBinding]
    }

    /// Emits a client script for the given page, or an empty string if the
    /// page has no reactive declarations or event bindings.
    public static func emit(page: some Page, environment: Environment) -> String {
        emitWithSourceMap(page: page, environment: environment).script
    }

    /// Emits a client script and an accompanying v3 source map for the given page.
    ///
    /// Discovers page-level state and walks the node tree to find component-level
    /// state. Page-level declarations are emitted at the top scope. Component-level
    /// declarations are wrapped in IIFEs scoped via `data-scope`.
    public static func emitWithSourceMap(
        page: some Page,
        environment: Environment,
        sourceFile: String? = nil
    ) -> EmitResult {
        let pageStates = extractStates(from: page)
        let pageComputeds = extractComputeds(from: page)
        let pageActions = extractActions(from: page)
        let pageBindings = extractEventBindings(from: page.body)
        let componentScopes = extractComponentScopes(from: page.body)

        let hasPageReactivity =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageActions.isEmpty || !pageBindings.isEmpty
        let hasComponentReactivity = !componentScopes.isEmpty

        guard hasPageReactivity || hasComponentReactivity else {
            return EmitResult(script: "", sourceMap: nil, scriptID: nil)
        }

        let pagePath = type(of: page).path
        let scriptID = stableScriptID(for: pagePath)
        let swiftSource = sourceFile ?? "Page(\(pagePath))"

        var js = ""
        var line = 0
        var mapBuilder = SourceMap.Builder(file: "\(scriptID).js")

        // Page-level state declarations.
        for s in pageStates {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: s.name
            )
            js.append("const \(s.name) = Score.state(\(s.initialValue));\n")
            line += 1
        }

        for c in pageComputeds {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: c.name
            )
            js.append("const \(c.name) = Score.computed(() => \(c.name));\n")
            line += 1
        }

        for a in pageActions {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: a.name
            )
            if a.jsBody.isEmpty {
                js.append("function \(a.name)(event) {}\n")
            } else {
                js.append("function \(a.name)(event) { \(a.jsBody); }\n")
            }
            line += 1
        }

        // Page-level state effects.
        for s in pageStates where !s.jsEffect.isEmpty {
            js.append("Score.effect(function() { \(s.jsEffect); });\n")
            line += 1
        }

        // Page-level event bindings (outside any component scope).
        for b in pageBindings {
            js.append(
                "document.querySelector('[data-s=\"\(b.elementIndex)\"]')"
                    + ".addEventListener(\"\(b.event)\", \(b.handler));\n"
            )
            line += 1
        }

        // Component-scoped state (each wrapped in an IIFE).
        for scope in componentScopes {
            js.append("// scope: \(scope.name)\n")
            line += 1
            js.append("(function() {\n")
            line += 1
            js.append("  const scope = document.querySelector('[data-scope=\"\(scope.name)\"]');\n")
            line += 1

            for s in scope.states {
                js.append("  const \(s.name) = Score.state(\(s.initialValue));\n")
                line += 1
            }

            for c in scope.computeds {
                js.append("  const \(c.name) = Score.computed(() => \(c.name));\n")
                line += 1
            }

            for a in scope.actions {
                if a.jsBody.isEmpty {
                    js.append("  function \(a.name)(event) {}\n")
                } else {
                    js.append("  function \(a.name)(event) { \(a.jsBody); }\n")
                }
                line += 1
            }

            for s in scope.states where !s.jsEffect.isEmpty {
                js.append("  Score.effect(function() { \(s.jsEffect); });\n")
                line += 1
            }

            for b in scope.bindings {
                js.append(
                    "  scope.querySelector('[data-s=\"\(b.elementIndex)\"]')"
                        + ".addEventListener(\"\(b.event)\", \(b.handler));\n"
                )
                line += 1
            }

            js.append("})();\n")
            line += 1
        }

        if environment == .development {
            js.append("//# sourceMappingURL=/_score/maps/\(scriptID).js.map\n")
            let sourceMapJSON = mapBuilder.build()
            return EmitResult(
                script: "<script>\n\(js)</script>",
                sourceMap: sourceMapJSON,
                scriptID: scriptID
            )
        }

        return EmitResult(script: "<script>\n\(js)</script>", sourceMap: nil, scriptID: nil)
    }

    /// Produces a stable, URL-safe identifier from a page path.
    static func stableScriptID(for pagePath: String) -> String {
        let replaced = pagePath.replacingOccurrences(of: "/", with: "-")
        let safe = replaced.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return safe.isEmpty ? "index" : safe
    }

    // MARK: - State Extraction (Any Instance)

    /// Extracts `@State` property declarations from any instance using `Mirror`.
    public static func extractStates(from instance: Any) -> [StateDeclaration] {
        var results: [StateDeclaration] = []
        let mirror = Mirror(reflecting: instance)
        for child in mirror.children {
            guard let label = child.label else { continue }
            let valueMirror = Mirror(reflecting: child.value)
            guard valueMirror.subjectType is any _StateMarker.Type else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            let initial = formatJSValue(extractWrappedValue(from: child.value))
            let effect = (child.value as? any _StateMarker)?.stateJSEffect ?? ""
            results.append(StateDeclaration(name: name, initialValue: initial, jsEffect: effect))
        }
        return results
    }

    /// Extracts `@Computed` property declarations from any instance using `Mirror`.
    public static func extractComputeds(from instance: Any) -> [ComputedDeclaration] {
        var results: [ComputedDeclaration] = []
        let mirror = Mirror(reflecting: instance)
        for child in mirror.children {
            guard let label = child.label else { continue }
            let valueMirror = Mirror(reflecting: child.value)
            guard valueMirror.subjectType is any _ComputedMarker.Type else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            results.append(ComputedDeclaration(name: name))
        }
        return results
    }

    /// Extracts `@Action` property declarations from any instance using `Mirror`.
    public static func extractActions(from instance: Any) -> [ActionDeclaration] {
        var results: [ActionDeclaration] = []
        let mirror = Mirror(reflecting: instance)
        for child in mirror.children {
            guard let label = child.label else { continue }
            guard let action = child.value as? Action else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            results.append(ActionDeclaration(name: name, jsBody: action.jsBody))
        }
        return results
    }

    /// Walks a node tree and extracts all event bindings.
    public static func extractEventBindings(from node: some Node) -> [EventBinding] {
        var bindings: [EventBinding] = []
        var index = 0
        walkForEvents(node, bindings: &bindings, index: &index)
        return bindings
    }

    // MARK: - Component Scope Discovery

    /// Walks the node tree to find `Component` instances with `@State` properties.
    ///
    /// Returns a `ComponentScope` for each stateful component found,
    /// containing its state, action, and event binding declarations.
    public static func extractComponentScopes(from node: some Node) -> [ComponentScope] {
        var scopes: [ComponentScope] = []
        walkForScopes(node, scopes: &scopes)
        return scopes
    }

    /// Builds a `scopeInjector` closure suitable for passing to `HTMLRenderer`.
    ///
    /// The injector inspects any node via `Mirror` and returns `ScopeInfo`
    /// if it contains `@State` properties.
    public static func buildScopeInjector() -> @Sendable (Any) -> ScopeInfo? {
        { node in
            let states = extractStates(from: node)
            guard !states.isEmpty else { return nil }

            // Derive scope name from type name (strip generic params, lowercase).
            let fullTypeName = String(describing: type(of: node))
            let baseName = fullTypeName.components(separatedBy: "<").first ?? fullTypeName
            let scopeName = baseName.lowercased()

            return ScopeInfo(
                name: scopeName,
                states: states.map { ($0.name, $0.initialValue) }
            )
        }
    }

    // MARK: - Private Helpers

    private static func walkForScopes(
        _ node: some Node,
        scopes: inout [ComponentScope]
    ) {
        // Check if this node is a Component with @State.
        if node is any Component {
            let states = extractStates(from: node)
            if !states.isEmpty {
                let computeds = extractComputeds(from: node)
                let actions = extractActions(from: node)
                let bindings = extractEventBindings(from: node.body)

                let fullTypeName = String(describing: type(of: node))
                let baseName = fullTypeName.components(separatedBy: "<").first ?? fullTypeName
                let scopeName = baseName.lowercased()

                scopes.append(
                    ComponentScope(
                        name: scopeName,
                        states: states,
                        computeds: computeds,
                        actions: actions,
                        bindings: bindings
                    ))
                // Continue walking into the component's body for nested components.
                walkForScopes(node.body, scopes: &scopes)
                return
            }
        }

        // Not a stateful component — check if it's a tree structure node.
        if let modified = node as? any _NodeContainingModifiersForJS {
            modified.walkChildForScopes(scopes: &scopes)
            return
        }

        if let walkable = node as? any _JSWalkable {
            walkable.walkChildrenForScopes(scopes: &scopes)
            return
        }

        // Composite node (Component without state, or other) — expand body.
        if !(node.body is Never) {
            walkForScopes(node.body, scopes: &scopes)
        }
    }

    private static func walkForEvents(
        _ node: some Node,
        bindings: inout [EventBinding],
        index: inout Int
    ) {
        if let modified = node as? any _NodeContainingModifiersForJS {
            let currentIndex = index
            for modifier in modified.modifiers {
                if let event = modifier as? EventBindingModifier {
                    bindings.append(
                        EventBinding(
                            elementIndex: currentIndex,
                            event: event.event.name,
                            handler: event.handler
                        ))
                }
            }
            index += 1
            modified.walkChildForJS(bindings: &bindings, index: &index)
            return
        }

        if let walkable = node as? any _JSWalkable {
            walkable.walkChildrenForJS(bindings: &bindings, index: &index)
            return
        }

        walkForEvents(node.body, bindings: &bindings, index: &index)
    }

    static func extractWrappedValue(from wrapper: Any) -> Any {
        let mirror = Mirror(reflecting: wrapper)
        for child in mirror.children where child.label == "wrappedValue" {
            return child.value
        }
        return wrapper
    }

    static func formatJSValue(_ value: Any) -> String {
        switch value {
        case let s as String: return "\"\(escapeJS(s))\""
        case let b as Bool: return b ? "true" : "false"
        case let i as Int: return "\(i)"
        case let d as Double: return "\(d)"
        default: return "\"\(escapeJS(String(describing: value)))\""
        }
    }

    private static func escapeJS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}

// MARK: - Tree Walking Protocols (Event Bindings)

protocol _NodeContainingModifiersForJS {
    var modifiers: [any ModifierValue] { get }
    func walkChildForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int)
    func walkChildForScopes(scopes: inout [JSEmitter.ComponentScope])
}

extension ModifiedNode: _NodeContainingModifiersForJS {
    func walkChildForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        JSEmitter.extractEventsFromChild(content, bindings: &bindings, index: &index)
    }

    func walkChildForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        JSEmitter.extractScopesFromChild(content, scopes: &scopes)
    }
}

extension JSEmitter {
    static func extractEventsFromChild(
        _ node: some Node,
        bindings: inout [EventBinding],
        index: inout Int
    ) {
        walkForEvents(node, bindings: &bindings, index: &index)
    }

    static func extractScopesFromChild(
        _ node: some Node,
        scopes: inout [ComponentScope]
    ) {
        walkForScopes(node, scopes: &scopes)
    }
}

// MARK: - Tree Walking Protocols (Scope Discovery)

protocol _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int)
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope])
}

/// Default scope-walking for domain nodes: uses Mirror to find child
/// `Node` properties (named "content", "summary", etc.) and recurses.
extension _JSWalkable {
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let node = child.value as? any Node {
                JSEmitter.extractScopesFromChild(node, scopes: &scopes)
            }
        }
    }
}

extension EmptyNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension TextNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension RawTextNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension TupleNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        repeat JSEmitter.extractEventsFromChild(
            each children, bindings: &bindings, index: &index)
    }

    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        repeat JSEmitter.extractScopesFromChild(each children, scopes: &scopes)
    }
}

extension ConditionalNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        switch storage {
        case .first(let node):
            JSEmitter.extractEventsFromChild(node, bindings: &bindings, index: &index)
        case .second(let node):
            JSEmitter.extractEventsFromChild(node, bindings: &bindings, index: &index)
        }
    }

    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        switch storage {
        case .first(let node):
            JSEmitter.extractScopesFromChild(node, scopes: &scopes)
        case .second(let node):
            JSEmitter.extractScopesFromChild(node, scopes: &scopes)
        }
    }
}

extension OptionalNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        if let node = wrapped {
            JSEmitter.extractEventsFromChild(node, bindings: &bindings, index: &index)
        }
    }

    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        if let node = wrapped {
            JSEmitter.extractScopesFromChild(node, scopes: &scopes)
        }
    }
}

extension ForEachNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        for item in data {
            JSEmitter.extractEventsFromChild(content(item), bindings: &bindings, index: &index)
        }
    }

    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        for item in data {
            JSEmitter.extractScopesFromChild(content(item), scopes: &scopes)
        }
    }
}

extension ArrayNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        for child in children {
            JSEmitter.extractEventsFromChild(child, bindings: &bindings, index: &index)
        }
    }

    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {
        for child in children {
            JSEmitter.extractScopesFromChild(child, scopes: &scopes)
        }
    }
}
