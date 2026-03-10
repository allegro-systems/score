import ScoreCore

/// Extracts reactive bindings from a `Page` and emits client-side JavaScript.
public struct JSEmitter: Sendable {

    /// Information about a `@State` property extracted via Mirror.
    public struct StateInfo: Sendable {
        public let name: String
        public let initialValue: String
        public let storageKey: String
    }

    /// Information about a `@Computed` property extracted via Mirror.
    public struct ComputedInfo: Sendable {
        public let name: String
        public let body: String
    }

    /// Information about an `@Action` function extracted via Mirror.
    public struct ActionInfo: Sendable {
        public let name: String
        public let body: String
    }

    /// Information about an event binding extracted from a node tree.
    public struct EventBinding: Sendable {
        public let event: String
        public let handler: String
    }

    /// Information about a reactive DOM binding extracted from a node tree.
    public struct ReactiveBinding: Sendable {
        /// The kind of reactive binding.
        public enum Kind: Sendable {
            /// Toggles the element's `hidden` attribute based on a boolean state.
            case visibility(stateName: String)
            /// Updates the element's `textContent` from a state or computed value.
            case text(bindingName: String)
        }

        public let kind: Kind
    }

    /// Groups the reactive declarations and bindings belonging to a single `Element`.
    struct ElementScope {
        var states: [StateInfo] = []
        var computeds: [ComputedInfo] = []
        var actions: [ActionInfo] = []
        var bindings: [EventBinding] = []
        var reactiveBindings: [ReactiveBinding] = []
    }

    /// Checks whether a node is a leaf (has `Body == Never`) without
    /// evaluating `body`, which would trigger `fatalError` on leaf nodes.
    private static func isLeafNode<N: Node>(_ node: N) -> Bool {
        N.Body.self == Never.self
    }

    private init() {}

    // MARK: - Extraction

    /// Extracts all `@State` properties from a page instance.
    public static func extractStates(from page: some Page) -> [StateInfo] {
        extractStatesFromMirror(Mirror(reflecting: page))
    }

    /// Extracts all `@Computed` properties from a page instance.
    public static func extractComputeds(from page: some Page) -> [ComputedInfo] {
        extractComputedsFromMirror(Mirror(reflecting: page))
    }

    /// Extracts all `@Action` functions from a page instance.
    ///
    /// The `@Action` macro generates `_action_<name>` peer properties of type
    /// `ActionDescriptor`. This method finds them via Mirror reflection.
    public static func extractActions(from page: some Page) -> [ActionInfo] {
        extractActionsFromMirror(Mirror(reflecting: page))
    }

    /// Extracts `@State`, `@Computed`, and `@Action` declarations from
    /// all `Element` instances found in a node tree.
    public static func extractFromTree(_ node: some Node) -> (states: [StateInfo], computeds: [ComputedInfo], actions: [ActionInfo]) {
        var states: [StateInfo] = []
        var computeds: [ComputedInfo] = []
        var actions: [ActionInfo] = []
        walkForElements(node, states: &states, computeds: &computeds, actions: &actions)
        return (states, computeds, actions)
    }

    /// Extracts all event bindings from a node tree.
    public static func extractEventBindings(from node: some Node) -> [EventBinding] {
        var bindings: [EventBinding] = []
        walkForEvents(node, into: &bindings)
        return bindings
    }

    // MARK: - Scoped Extraction

    /// Walks the node tree and groups declarations per `Element`, returning
    /// each Element's scope plus any page-level (non-Element) bindings.
    static func extractElementScopes(
        from node: some Node
    ) -> (scopes: [ElementScope], pageLevelBindings: [EventBinding], pageLevelReactive: [ReactiveBinding]) {
        var scopes: [ElementScope] = []
        var pageLevelBindings: [EventBinding] = []
        var pageLevelReactive: [ReactiveBinding] = []
        walkForScopes(node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
        return (scopes, pageLevelBindings, pageLevelReactive)
    }

    /// Recursively walks the node tree. When an `Element` is encountered,
    /// its mirror declarations and subtree bindings are captured as one scope.
    /// Bindings outside any Element are collected into page-level arrays.
    static func walkForScopes(
        _ node: some Node,
        scopes: inout [ElementScope],
        pageLevelBindings: inout [EventBinding],
        pageLevelReactive: inout [ReactiveBinding]
    ) {
        if node is any Element {
            var scope = ElementScope()
            let mirror = Mirror(reflecting: node)
            scope.states = extractStatesFromMirror(mirror)
            scope.computeds = extractComputedsFromMirror(mirror)
            scope.actions = extractActionsFromMirror(mirror)

            if !isLeafNode(node) {
                walkForEvents(node.body, into: &scope.bindings)
                walkForReactiveBindings(node.body, into: &scope.reactiveBindings)
            }

            if !scope.states.isEmpty || !scope.computeds.isEmpty
                || !scope.actions.isEmpty || !scope.bindings.isEmpty
                || !scope.reactiveBindings.isEmpty
            {
                scopes.append(scope)
            }
            return
        }

        if let reactiveText = node as? ReactiveTextNode {
            pageLevelReactive.append(
                ReactiveBinding(kind: .text(bindingName: reactiveText.bindingName)))
            return
        }

        if let modified = node as? any ModifiedNodeAccessible {
            for modifier in modified.accessibleModifiers {
                if let eventMod = modifier as? EventBindingModifier {
                    pageLevelBindings.append(
                        EventBinding(event: eventMod.event.name, handler: eventMod.handler))
                }
                if let visMod = modifier as? ReactiveVisibilityModifier {
                    pageLevelReactive.append(
                        ReactiveBinding(kind: .visibility(stateName: visMod.stateName)))
                }
            }
            modified.walkContentForScopes(scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
            return
        }

        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSScoped(scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
            return
        }

        if !isLeafNode(node) {
            walkForScopes(node.body, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
        }
    }

    /// Walks the node tree collecting reactive bindings.
    static func walkForReactiveBindings(_ node: some Node, into bindings: inout [ReactiveBinding]) {
        if let reactiveText = node as? ReactiveTextNode {
            bindings.append(ReactiveBinding(kind: .text(bindingName: reactiveText.bindingName)))
            return
        }

        if let modified = node as? any ModifiedNodeAccessible {
            for modifier in modified.accessibleModifiers {
                if let visMod = modifier as? ReactiveVisibilityModifier {
                    bindings.append(ReactiveBinding(kind: .visibility(stateName: visMod.stateName)))
                }
            }
            modified.walkContentForReactive(into: &bindings)
            return
        }

        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSReactive(into: &bindings)
            return
        }

        if !isLeafNode(node) {
            walkForReactiveBindings(node.body, into: &bindings)
        }
    }

    // MARK: - Client Runtime

    /// Minimal signals runtime shared across all reactive pages.
    public static let clientRuntime = """
        const Score=(()=>{let t=null;function state(v){let subs=new Set();return{get(){if(t)subs.add(t);return v},set(n){if(n===v)return;v=n;for(const fn of subs)fn()}}}function effect(fn){const run=()=>{t=run;try{fn()}finally{t=null}};run()}function computed(fn){let s=state(undefined);effect(()=>s.set(fn()));return{get:s.get}}return{state,effect,computed}})();
        """

    // MARK: - Emission

    /// The result of analyzing a page's reactive content.
    public struct EmissionResult: Sendable {
        /// The page-specific JavaScript (state, computed, actions, bindings).
        /// Empty if the page has no reactive content.
        public let pageJS: String
        /// Whether this page requires the Score signals runtime.
        public let needsRuntime: Bool
    }

    /// Analyzes a page and returns its reactive JavaScript separately from
    /// the shared runtime. Use this when externalizing scripts to files.
    public static func emitPageScript(page: some Page) -> EmissionResult {
        let pageStates = extractStates(from: page)
        let pageComputeds = extractComputeds(from: page)
        let pageActions = extractActions(from: page)

        let (elementScopes, pageLevelBindings, pageLevelReactive) = extractElementScopes(from: page.body)

        let hasPageLevel =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageActions.isEmpty || !pageLevelBindings.isEmpty
            || !pageLevelReactive.isEmpty
        let hasElementLevel = !elementScopes.isEmpty

        guard hasPageLevel || hasElementLevel else {
            return EmissionResult(pageJS: "", needsRuntime: false)
        }

        let needsRuntime =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageLevelReactive.isEmpty
            || elementScopes.contains(where: {
                !$0.states.isEmpty || !$0.computeds.isEmpty || !$0.reactiveBindings.isEmpty
            })

        var js = ""
        var bindingOffset = 0
        var reactiveOffset = 0

        emitDeclarations(
            states: pageStates, computeds: pageComputeds,
            actions: pageActions, bindings: pageLevelBindings,
            reactiveBindings: pageLevelReactive,
            bindingOffset: &bindingOffset, reactiveOffset: &reactiveOffset, into: &js
        )

        for scope in elementScopes {
            js.append("{\n")
            emitDeclarations(
                states: scope.states, computeds: scope.computeds,
                actions: scope.actions, bindings: scope.bindings,
                reactiveBindings: scope.reactiveBindings,
                bindingOffset: &bindingOffset, reactiveOffset: &reactiveOffset, into: &js
            )
            js.append("}\n")
        }

        return EmissionResult(pageJS: js, needsRuntime: needsRuntime)
    }

    /// Emits a `<script>` tag for a page, or an empty string if the page
    /// has no reactive properties or event bindings.
    ///
    /// This is a convenience that inlines both the runtime and page JS.
    /// For external script files, use ``emitPageScript(page:)`` instead.
    public static func emit(page: some Page, environment: Environment) -> String {
        let result = emitPageScript(page: page)
        guard !result.pageJS.isEmpty else { return "" }

        var js = ""
        if result.needsRuntime {
            js.append(clientRuntime)
        }
        js.append(result.pageJS)
        return "<script>\n\(js)</script>"
    }

    /// Emits `const`, `function`, `addEventListener`, and `Score.effect` lines
    /// for a set of declarations, advancing binding offsets as they are emitted.
    private static func emitDeclarations(
        states: [StateInfo], computeds: [ComputedInfo],
        actions: [ActionInfo], bindings: [EventBinding],
        reactiveBindings: [ReactiveBinding] = [],
        bindingOffset: inout Int, reactiveOffset: inout Int, into js: inout String
    ) {
        for state in states {
            if state.storageKey.isEmpty {
                js.append("const \(state.name) = Score.state(\(state.initialValue));\n")
            } else {
                js.append("const \(state.name) = Score.state((()=>{var v=localStorage.getItem(\"\(state.storageKey)\");return v!==null?JSON.parse(v):\(state.initialValue)})());\n")
            }
        }
        for computed in computeds {
            if computed.body.isEmpty {
                js.append("const \(computed.name) = Score.computed(() => \(computed.name));\n")
            } else {
                js.append("const \(computed.name) = Score.computed(() => \(computed.body));\n")
            }
        }
        for action in actions {
            if action.body.isEmpty {
                js.append("function \(action.name)(event) {}\n")
            } else {
                js.append("function \(action.name)(event) { \(action.body) }\n")
            }
        }
        for binding in bindings {
            js.append(
                "document.querySelector(\"[data-s=\\\"\(bindingOffset)\\\"]\").addEventListener(\"\(binding.event)\", \(binding.handler));\n"
            )
            bindingOffset += 1
        }
        for state in states where !state.storageKey.isEmpty {
            js.append("Score.effect(() => { localStorage.setItem(\"\(state.storageKey)\",JSON.stringify(\(state.name).get())); });\n")
        }
        for reactive in reactiveBindings {
            switch reactive.kind {
            case .visibility(let stateName):
                let selector = "document.querySelector(\"[data-r=\\\"\(reactiveOffset)\\\"]\")"
                js.append("Score.effect(() => { \(selector).hidden = !\(stateName).get(); });\n")
                reactiveOffset += 1
            case .text(let bindingName):
                js.append(
                    "Score.effect(() => { document.querySelector('[data-bind=\"\(bindingName)\"]').textContent = \(bindingName).get(); });\n"
                )
            }
        }
    }

    // MARK: - Helpers

    private static func extractStatesFromMirror(_ mirror: Mirror) -> [StateInfo] {
        var states: [StateInfo] = []
        for child in mirror.children {
            guard let descriptor = child.value as? StateDescriptor else { continue }
            states.append(
                StateInfo(
                    name: descriptor.name,
                    initialValue: descriptor.jsInitialValue,
                    storageKey: descriptor.storageKey
                ))
        }
        return states
    }

    private static func extractComputedsFromMirror(_ mirror: Mirror) -> [ComputedInfo] {
        var computeds: [ComputedInfo] = []
        for child in mirror.children {
            if let descriptor = child.value as? ComputedDescriptor {
                computeds.append(ComputedInfo(name: descriptor.name, body: descriptor.body))
            }
        }
        return computeds
    }

    private static func extractActionsFromMirror(_ mirror: Mirror) -> [ActionInfo] {
        var actions: [ActionInfo] = []
        for child in mirror.children {
            guard let descriptor = child.value as? ActionDescriptor else { continue }
            actions.append(ActionInfo(name: descriptor.name, body: descriptor.body))
        }
        return actions
    }

    static func walkForElements(
        _ node: some Node,
        states: inout [StateInfo],
        computeds: inout [ComputedInfo],
        actions: inout [ActionInfo]
    ) {
        if node is any Element {
            let mirror = Mirror(reflecting: node)
            states.append(contentsOf: extractStatesFromMirror(mirror))
            computeds.append(contentsOf: extractComputedsFromMirror(mirror))
            actions.append(contentsOf: extractActionsFromMirror(mirror))
        }

        if let modified = node as? any ModifiedNodeAccessible {
            modified.walkContentForElements(states: &states, computeds: &computeds, actions: &actions)
            return
        }

        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSElements(states: &states, computeds: &computeds, actions: &actions)
            return
        }

        if !isLeafNode(node) {
            walkForElements(node.body, states: &states, computeds: &computeds, actions: &actions)
        }
    }

    static func walkForEvents(_ node: some Node, into bindings: inout [EventBinding]) {
        if let modified = node as? any ModifiedNodeAccessible {
            for modifier in modified.accessibleModifiers {
                if let eventMod = modifier as? EventBindingModifier {
                    bindings.append(
                        EventBinding(
                            event: eventMod.event.name,
                            handler: eventMod.handler
                        ))
                }
            }
            modified.walkContent(into: &bindings)
            return
        }

        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSEvents(into: &bindings)
            return
        }

        if !isLeafNode(node) {
            walkForEvents(node.body, into: &bindings)
        }
    }
}

// MARK: - Internal Protocols for Walking

/// Internal protocol for accessing ModifiedNode's modifiers and content.
protocol ModifiedNodeAccessible {
    var accessibleModifiers: [any ModifierValue] { get }
    func walkContent(into bindings: inout [JSEmitter.EventBinding])
    func walkContentForElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    )
    func walkContentForScopes(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    )
    func walkContentForReactive(into bindings: inout [JSEmitter.ReactiveBinding])
}

extension ModifiedNode: ModifiedNodeAccessible {
    var accessibleModifiers: [any ModifierValue] { modifiers }
    func walkContent(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    func walkContentForElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForElements(content, states: &states, computeds: &computeds, actions: &actions)
    }
    func walkContentForScopes(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        JSEmitter.walkForScopes(content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
    }
    func walkContentForReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}

/// Internal protocol for primitive nodes to walk their children for event bindings.
protocol JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding])
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    )
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    )
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding])
}

/// Internal protocol for container nodes that walk a single `content` child.
protocol JSContentWalkable: JSEventWalkable {
    associatedtype Content: Node
    var content: Content { get }
}

extension JSContentWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForElements(content, states: &states, computeds: &computeds, actions: &actions)
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        JSEmitter.walkForScopes(content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}

/// Internal protocol for leaf nodes with no children to walk.
protocol JSLeafWalkable: JSEventWalkable {}

extension JSLeafWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {}
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {}
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {}
}

// Builder nodes
extension TupleNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        repeat JSEmitter.walkForEvents(each children, into: &bindings)
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        repeat JSEmitter.walkForElements(each children, states: &states, computeds: &computeds, actions: &actions)
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        repeat JSEmitter.walkForScopes(each children, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        repeat JSEmitter.walkForReactiveBindings(each children, into: &bindings)
    }
}

extension ConditionalNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForEvents(node, into: &bindings)
        case .second(let node): JSEmitter.walkForEvents(node, into: &bindings)
        }
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        switch storage {
        case .first(let node): JSEmitter.walkForElements(node, states: &states, computeds: &computeds, actions: &actions)
        case .second(let node): JSEmitter.walkForElements(node, states: &states, computeds: &computeds, actions: &actions)
        }
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        switch storage {
        case .first(let node): JSEmitter.walkForScopes(node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
        case .second(let node): JSEmitter.walkForScopes(node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
        }
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForReactiveBindings(node, into: &bindings)
        case .second(let node): JSEmitter.walkForReactiveBindings(node, into: &bindings)
        }
    }
}

extension OptionalNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        if let node = wrapped { JSEmitter.walkForEvents(node, into: &bindings) }
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        if let node = wrapped { JSEmitter.walkForElements(node, states: &states, computeds: &computeds, actions: &actions) }
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        if let node = wrapped { JSEmitter.walkForScopes(node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive) }
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        if let node = wrapped { JSEmitter.walkForReactiveBindings(node, into: &bindings) }
    }
}

extension ForEachNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for item in data { JSEmitter.walkForEvents(content(item), into: &bindings) }
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        for item in data { JSEmitter.walkForElements(content(item), states: &states, computeds: &computeds, actions: &actions) }
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        for item in data { JSEmitter.walkForScopes(content(item), scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive) }
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        for item in data { JSEmitter.walkForReactiveBindings(content(item), into: &bindings) }
    }
}

extension ArrayNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for child in children { JSEmitter.walkForEvents(child, into: &bindings) }
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        for child in children { JSEmitter.walkForElements(child, states: &states, computeds: &computeds, actions: &actions) }
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        for child in children { JSEmitter.walkForScopes(child, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive) }
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        for child in children { JSEmitter.walkForReactiveBindings(child, into: &bindings) }
    }
}

extension EmptyNode: JSLeafWalkable {}
extension TextNode: JSLeafWalkable {}
extension RawTextNode: JSLeafWalkable {}
extension ReactiveTextNode: JSLeafWalkable {}

// Container domain nodes — walk content
extension Heading: JSContentWalkable {}
extension Paragraph: JSContentWalkable {}
extension Text: JSContentWalkable {}
extension Strong: JSContentWalkable {}
extension Emphasis: JSContentWalkable {}
extension Small: JSContentWalkable {}
extension Mark: JSContentWalkable {}
extension Code: JSContentWalkable {}
extension Preformatted: JSContentWalkable {}
extension Blockquote: JSContentWalkable {}
extension Address: JSContentWalkable {}
extension Stack: JSContentWalkable {}
extension Main: JSContentWalkable {}
extension Section: JSContentWalkable {}
extension Article: JSContentWalkable {}
extension Header: JSContentWalkable {}
extension Footer: JSContentWalkable {}
extension Aside: JSContentWalkable {}
extension Navigation: JSContentWalkable {}
extension Group: JSContentWalkable {}
extension Link: JSContentWalkable {}
extension Button: JSContentWalkable {}
extension Form: JSContentWalkable {}
extension Label: JSContentWalkable {}
extension Select: JSContentWalkable {}
extension Option: JSContentWalkable {}
extension OptionGroup: JSContentWalkable {}
extension Fieldset: JSContentWalkable {}
extension Legend: JSContentWalkable {}
extension Output: JSContentWalkable {}
extension DataList: JSContentWalkable {}
extension Dialog: JSContentWalkable {}
extension Menu: JSContentWalkable {}
extension Summary: JSContentWalkable {}
extension Details: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(summary, into: &bindings)
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForElements(summary, states: &states, computeds: &computeds, actions: &actions)
        JSEmitter.walkForElements(content, states: &states, computeds: &computeds, actions: &actions)
    }
    func walkForJSScoped(
        scopes: inout [JSEmitter.ElementScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding]
    ) {
        JSEmitter.walkForScopes(summary, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
        JSEmitter.walkForScopes(content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive)
    }
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(summary, into: &bindings)
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}
extension UnorderedList: JSContentWalkable {}
extension OrderedList: JSContentWalkable {}
extension ListItem: JSContentWalkable {}
extension DescriptionList: JSContentWalkable {}
extension DescriptionTerm: JSContentWalkable {}
extension DescriptionDetails: JSContentWalkable {}
extension Table: JSContentWalkable {}
extension TableCaption: JSContentWalkable {}
extension TableHead: JSContentWalkable {}
extension TableBody: JSContentWalkable {}
extension TableFooter: JSContentWalkable {}
extension TableRow: JSContentWalkable {}
extension TableHeaderCell: JSContentWalkable {}
extension TableCell: JSContentWalkable {}
extension TableColumnGroup: JSContentWalkable {}
extension Figure: JSContentWalkable {}
extension FigureCaption: JSContentWalkable {}
extension Audio: JSContentWalkable {}
extension Video: JSContentWalkable {}
extension Picture: JSContentWalkable {}
extension Canvas: JSContentWalkable {}

// Leaf nodes
extension HorizontalRule: JSLeafWalkable {}
extension LineBreak: JSLeafWalkable {}
extension Image: JSLeafWalkable {}
extension Input: JSLeafWalkable {}
extension TextArea: JSLeafWalkable {}
extension Progress: JSLeafWalkable {}
extension Meter: JSLeafWalkable {}
extension Source: JSLeafWalkable {}
extension Track: JSLeafWalkable {}
extension TableColumn: JSLeafWalkable {}
