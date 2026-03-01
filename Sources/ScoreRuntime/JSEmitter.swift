import Foundation
import ScoreCore

/// Emits client-side JavaScript that wires reactive signals and event
/// listeners for a page or component.
///
/// `JSEmitter` inspects a page instance using `Mirror` to discover
/// `@State`, `@Computed`, and `@Action` property wrappers, and walks the
/// rendered node tree to find `EventBindingModifier` values. It then
/// produces a `<script>` block that:
///
/// 1. Creates a `Score.state()` call per `@State` with its initial value
/// 2. Creates a `Score.computed()` call per `@Computed`
/// 3. Creates a plain function per `@Action`
/// 4. Attaches `addEventListener` calls per `EventBindingModifier`
/// 5. Creates `Score.effect()` calls that bind signals to DOM elements
///
/// ### Element Targeting
///
/// In development mode, reactive elements receive `data-s="N"` attributes
/// and JavaScript uses `document.querySelector('[data-s="N"]')`. In
/// production, the compiler would generate direct DOM traversal paths.
///
/// ### Example
///
/// ```swift
/// let script = JSEmitter.emit(page: myPage, environment: .development)
/// // Returns a <script> tag string or empty string if no reactivity
/// ```
public enum JSEmitter: Sendable {

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

    /// Emits a client script for the given page, or an empty string if the
    /// page has no reactive declarations or event bindings.
    ///
    /// - Parameters:
    ///   - page: The page instance to inspect for reactive properties.
    ///   - environment: The current build environment.
    /// - Returns: A `<script>` tag string, or empty if no reactivity is needed.
    public static func emit(page: some Page, environment: Environment) -> String {
        emitWithSourceMap(page: page, environment: environment).script
    }

    /// Emits a client script and an accompanying v3 source map for the given page.
    ///
    /// In development mode the returned ``EmitResult`` includes a source map
    /// and the script tag contains a `sourceMappingURL` comment. In production
    /// the source map is `nil`.
    ///
    /// - Parameters:
    ///   - page: The page instance to inspect for reactive properties.
    ///   - environment: The current build environment.
    ///   - sourceFile: The Swift source file path embedded in the source map.
    /// - Returns: An ``EmitResult`` with the script, optional source map, and script ID.
    public static func emitWithSourceMap(
        page: some Page,
        environment: Environment,
        sourceFile: String? = nil
    ) -> EmitResult {
        let states = extractStates(from: page)
        let computeds = extractComputeds(from: page)
        let actions = extractActions(from: page)
        let bindings = extractEventBindings(from: page.body)

        guard !states.isEmpty || !computeds.isEmpty || !actions.isEmpty || !bindings.isEmpty else {
            return EmitResult(script: "", sourceMap: nil, scriptID: nil)
        }

        let pagePath = type(of: page).path
        let scriptID = stableScriptID(for: pagePath)
        let swiftSource = sourceFile ?? "Page(\(pagePath))"

        var js = ""
        var line = 0
        var mapBuilder = SourceMap.Builder(file: "\(scriptID).js")

        for s in states {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: s.name
            )
            js.append("const \(s.name) = Score.state(\(s.initialValue));\n")
            line += 1
        }

        for c in computeds {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: c.name
            )
            js.append("const \(c.name) = Score.computed(() => \(c.name));\n")
            line += 1
        }

        for a in actions {
            mapBuilder.addMapping(
                generatedLine: line, generatedColumn: 0,
                source: swiftSource, sourceLine: line, sourceColumn: 0,
                name: a.name
            )
            js.append("function \(a.name)() {}\n")
            line += 1
        }

        for b in bindings {
            let selector =
                environment == .development
                ? "document.querySelector('[data-s=\"\(b.elementIndex)\"]')"
                : "document.querySelector('[data-s=\"\(b.elementIndex)\"]')"
            js.append(
                "\(selector).addEventListener(\"\(b.event)\", \(b.handler));\n"
            )
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

    /// Extracts `@State` property declarations from a page using `Mirror`.
    ///
    /// - Parameter page: The page instance to inspect.
    /// - Returns: An array of state declarations with names and initial values.
    public static func extractStates(from page: some Page) -> [StateDeclaration] {
        var results: [StateDeclaration] = []
        let mirror = Mirror(reflecting: page)
        for child in mirror.children {
            guard let label = child.label else { continue }
            let valueMirror = Mirror(reflecting: child.value)
            guard valueMirror.subjectType is any _StateMarker.Type else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            let initial = formatJSValue(extractWrappedValue(from: child.value))
            results.append(StateDeclaration(name: name, initialValue: initial))
        }
        return results
    }

    /// Extracts `@Computed` property declarations from a page using `Mirror`.
    ///
    /// - Parameter page: The page instance to inspect.
    /// - Returns: An array of computed declarations.
    public static func extractComputeds(from page: some Page) -> [ComputedDeclaration] {
        var results: [ComputedDeclaration] = []
        let mirror = Mirror(reflecting: page)
        for child in mirror.children {
            guard let label = child.label else { continue }
            let valueMirror = Mirror(reflecting: child.value)
            guard valueMirror.subjectType is any _ComputedMarker.Type else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            results.append(ComputedDeclaration(name: name))
        }
        return results
    }

    /// Extracts `@Action` property declarations from a page using `Mirror`.
    ///
    /// - Parameter page: The page instance to inspect.
    /// - Returns: An array of action declarations.
    public static func extractActions(from page: some Page) -> [ActionDeclaration] {
        var results: [ActionDeclaration] = []
        let mirror = Mirror(reflecting: page)
        for child in mirror.children {
            guard let label = child.label else { continue }
            guard child.value is Action else { continue }
            let name = label.hasPrefix("_") ? String(label.dropFirst()) : label
            results.append(ActionDeclaration(name: name))
        }
        return results
    }

    /// Walks a node tree and extracts all event bindings.
    ///
    /// - Parameter node: The root node to walk.
    /// - Returns: An array of event bindings with element indices.
    public static func extractEventBindings(from node: some Node) -> [EventBinding] {
        var bindings: [EventBinding] = []
        var index = 0
        walkForEvents(node, bindings: &bindings, index: &index)
        return bindings
    }

    // MARK: - Private Helpers

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

    private static func extractWrappedValue(from wrapper: Any) -> Any {
        let mirror = Mirror(reflecting: wrapper)
        for child in mirror.children where child.label == "wrappedValue" {
            return child.value
        }
        return wrapper
    }

    private static func formatJSValue(_ value: Any) -> String {
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

// MARK: - Marker Protocols for Mirror Detection

/// Internal marker for `State` detection via `Mirror.subjectType`.
protocol _StateMarker {}
extension State: _StateMarker {}

/// Internal marker for `Computed` detection via `Mirror.subjectType`.
protocol _ComputedMarker {}
extension Computed: _ComputedMarker {}

// MARK: - Tree Walking Protocols

protocol _NodeContainingModifiersForJS {
    var modifiers: [any ModifierValue] { get }
    func walkChildForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int)
}

extension ModifiedNode: _NodeContainingModifiersForJS {
    func walkChildForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        JSEmitter.extractEventsFromChild(content, bindings: &bindings, index: &index)
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
}

protocol _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int)
}

extension EmptyNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
}

extension TextNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
}

extension TupleNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        repeat JSEmitter.extractEventsFromChild(
            each children, bindings: &bindings, index: &index)
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
}

extension OptionalNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        if let node = wrapped {
            JSEmitter.extractEventsFromChild(node, bindings: &bindings, index: &index)
        }
    }
}

extension ForEachNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        for item in data {
            JSEmitter.extractEventsFromChild(content(item), bindings: &bindings, index: &index)
        }
    }
}

extension ArrayNode: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {
        for child in children {
            JSEmitter.extractEventsFromChild(child, bindings: &bindings, index: &index)
        }
    }
}
