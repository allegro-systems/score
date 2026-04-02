import ScoreCore
import ScoreCSS

/// Extracts reactive bindings from a `Page` and emits client-side JavaScript.
public struct JSEmitter: Sendable {

    /// Information about a `@State` property extracted via Mirror.
    public struct StateInfo: Sendable {
        public let name: String
        public let initialValue: String
        public let storageKey: String
        public let isTheme: Bool
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
        public let parameters: [String]
    }

    /// Information about a `@Query` property extracted via Mirror.
    public struct QueryInfo: Sendable {
        public let name: String
        public let endpoint: String
        public let pollInterval: Int?
        public let isLocalFirst: Bool
    }

    /// Information about an event binding extracted from a node tree.
    public struct EventBinding: Sendable {
        public let event: String
        public let handler: String
        /// Server-rendered argument values to pass to the handler.
        public let args: [String]
        /// Whether `preventDefault()` should be called before the handler.
        public let preventDefault: Bool
        /// The document-order index assigned after scope extraction.
        /// When non-negative the emitter uses this value instead of a running counter,
        /// keeping indices stable after scope merging.
        public var documentIndex: Int = -1

        public init(event: String, handler: String, args: [String] = [], preventDefault: Bool = false) {
            self.event = event
            self.handler = handler
            self.args = args
            self.preventDefault = preventDefault
        }
    }

    /// Information about a reactive DOM binding extracted from a node tree.
    public struct ReactiveBinding: Sendable {
        /// The kind of reactive binding.
        public enum Kind: Sendable {
            /// Toggles the element's `hidden` attribute based on a boolean state.
            case visibility(stateName: String)
            /// Updates the element's `textContent` from a state or computed value.
            case text(bindingName: String)
            /// Two-way binding between an input element's value and a state signal.
            case inputValue(stateName: String)
        }

        public let kind: Kind
        /// The document-order index assigned after scope extraction.
        /// When non-negative the emitter uses this value instead of a running counter,
        /// keeping indices stable after scope merging.
        public var documentIndex: Int = -1
    }

    /// Groups the reactive declarations and bindings belonging to a single stateful `Component`.
    public struct ComponentScope: Sendable {
        public var name: String = ""
        /// The key used for merging scopes.  Scopes with the same
        /// `mergeKey` are combined into one shared scope.
        public var mergeKey: String = ""
        public var states: [StateInfo] = []
        public var computeds: [ComputedInfo] = []
        public var actions: [ActionInfo] = []
        public var queries: [QueryInfo] = []
        public var bindings: [EventBinding] = []
        public var reactiveBindings: [ReactiveBinding] = []
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
    /// all stateful `Component` instances found in a node tree.
    public static func extractFromTree(_ node: some Node) -> (states: [StateInfo], computeds: [ComputedInfo], actions: [ActionInfo]) {
        var states: [StateInfo] = []
        var computeds: [ComputedInfo] = []
        var actions: [ActionInfo] = []
        walkForComponents(node, states: &states, computeds: &computeds, actions: &actions)
        return (states, computeds, actions)
    }

    /// Extracts all event bindings from a node tree.
    public static func extractEventBindings(from node: some Node) -> [EventBinding] {
        var bindings: [EventBinding] = []
        walkForEvents(node, into: &bindings)
        return bindings
    }

    // MARK: - Scoped Extraction

    /// Walks the node tree and groups declarations per stateful `Component`, returning
    /// each component's scope plus any page-level (non-component) bindings.
    ///
    /// After the walk, each binding is stamped with a `documentIndex` that reflects
    /// its position in document order.  These indices remain stable through scope
    /// merging so the emitted `data-s` / `data-r` selectors always match the HTML.
    public static func extractComponentScopes(
        from node: some Node
    ) -> (scopes: [ComponentScope], pageLevelBindings: [EventBinding], pageLevelReactive: [ReactiveBinding]) {
        var scopes: [ComponentScope] = []
        var pageLevelBindings: [EventBinding] = []
        var pageLevelReactive: [ReactiveBinding] = []
        var eventCounter = 0
        var reactiveCounter = 0
        walkForScopes(
            node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )

        return (scopes, pageLevelBindings, pageLevelReactive)
    }

    /// Recursively walks the node tree. When a stateful `Component` is encountered,
    /// its mirror declarations and subtree bindings are captured as one scope.
    /// Bindings outside any stateful component are collected into page-level arrays.
    package static func walkForScopes(
        _ node: some Node,
        scopes: inout [ComponentScope],
        pageLevelBindings: inout [EventBinding],
        pageLevelReactive: inout [ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        if let component = node as? any Component {
            var scope = ComponentScope()
            let typeName = String(describing: type(of: node))
            scope.name = typeName

            // If the component declares a shared scopeKey, use it for merging.
            // Otherwise, use the current scope count as a unique key so each
            // instance stays independent.
            if let sharedKey = type(of: component).scopeKey {
                scope.mergeKey = "\(typeName):\(sharedKey)"
            } else {
                scope.mergeKey = "\(typeName)#\(scopes.count)"
            }

            let mirror = Mirror(reflecting: node)
            scope.states = extractStatesFromMirror(mirror)
            scope.computeds = extractComputedsFromMirror(mirror)
            scope.actions = extractActionsFromMirror(mirror)
            scope.queries = extractQueriesFromMirror(mirror)

            if !node.isLeafNode {
                walkForEvents(node.body, into: &scope.bindings)
                for i in scope.bindings.indices {
                    scope.bindings[i].documentIndex = eventCounter
                    eventCounter += 1
                }
                walkForReactiveBindings(node.body, into: &scope.reactiveBindings)
                // Scoped reactive bindings use data-bind (matched by name),
                // NOT data-r (matched by index), so they don't consume the
                // shared reactiveCounter.
            }

            if !scope.states.isEmpty || !scope.computeds.isEmpty
                || !scope.actions.isEmpty || !scope.bindings.isEmpty
                || !scope.reactiveBindings.isEmpty
            {
                scopes.append(scope)
            }

            if !node.isLeafNode {
                // Walk for nested components inside this component's body.
                // Use isolated counters because the outer walk already counted
                // this component's own bindings — the nested walk only looks
                // for deeper stateful components, and its page-level bindings
                // are discarded.
                var nestedBindings: [EventBinding] = []
                var nestedReactive: [ReactiveBinding] = []
                var nestedEventCounter = eventCounter
                var nestedReactiveCounter = reactiveCounter
                walkForScopes(
                    node.body, scopes: &scopes,
                    pageLevelBindings: &nestedBindings,
                    pageLevelReactive: &nestedReactive,
                    eventCounter: &nestedEventCounter,
                    reactiveCounter: &nestedReactiveCounter
                )
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
                    var binding = EventBinding(event: eventMod.event.name, handler: eventMod.handler, args: eventMod.args, preventDefault: eventMod.preventDefault)
                    binding.documentIndex = eventCounter
                    eventCounter += 1
                    pageLevelBindings.append(binding)
                }
                if let visMod = modifier as? ReactiveVisibilityModifier {
                    var binding = ReactiveBinding(kind: .visibility(stateName: visMod.stateName))
                    binding.documentIndex = reactiveCounter
                    reactiveCounter += 1
                    pageLevelReactive.append(binding)
                }
            }
            modified.walkContentForScopes(
                scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
            return
        }

        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSScoped(
                scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
            return
        }

        if !node.isLeafNode {
            walkForScopes(
                node.body, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        }
    }

    /// Walks the node tree collecting reactive bindings.
    package static func walkForReactiveBindings(_ node: some Node, into bindings: inout [ReactiveBinding]) {
        if node is any Component { return }

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

        if !node.isLeafNode {
            walkForReactiveBindings(node.body, into: &bindings)
        }
    }

    // MARK: - Client Runtime

    /// Minimal signals runtime shared across all reactive pages.
    ///
    /// Aligned with the TC39 Signals proposal (`Signal.State`, `Signal.Computed`),
    /// making it a near drop-in replacement once signals are standardised.
    /// `Signal.effect` is a Score addition not present in the TC39 spec.
    public static let clientRuntime = """
        const Signal=(()=>{let t=null;function State(v){let subs=new Set();return{get(){if(t)subs.add(t);return v},set(n){if(n===v)return;v=n;for(const fn of subs)fn()}}}function effect(fn){const run=()=>{t=run;try{fn()}finally{t=null}};run()}function Computed(fn){let s=new State(undefined);effect(()=>s.set(fn()));return{get:s.get}}return{State,effect,Computed}})();
        """

    /// Lightweight IntersectionObserver bootstrap for `.animateOnScroll()`.
    ///
    /// Elements with `data-scroll-animate` start at `opacity: 0` (set by CSS)
    /// and store their animation shorthand in `--score-scroll-animation`.
    /// When observed intersecting the viewport, the animation is applied and
    /// the element becomes visible. Elements with `once:0` in their config
    /// re-hide when they leave the viewport.
    public static let scrollObserverRuntime = """
        (function(){var els=document.querySelectorAll("[data-scroll-animate]");if(!els.length)return;var io=new IntersectionObserver(function(entries){entries.forEach(function(e){if(e.isIntersecting){var anim=getComputedStyle(e.target).getPropertyValue("--score-scroll-animation").trim();e.target.style.opacity="1";if(anim)e.target.style.animation=anim;var cfg=e.target.getAttribute("data-scroll-animate")||"";if(cfg.indexOf("once:0")===-1)io.unobserve(e.target)}else{var cfg=e.target.getAttribute("data-scroll-animate")||"";if(cfg.indexOf("once:0")!==-1){e.target.style.opacity="0";e.target.style.animation="none"}}})},{threshold:0.1,rootMargin:"0px"});els.forEach(function(el){var cfg=el.getAttribute("data-scroll-animate")||"";var m=cfg.match(/t:([\\d.]+)/);var threshold=m?parseFloat(m[1]):0.1;if(threshold!==0.1){var custom=new IntersectionObserver(function(entries){entries.forEach(function(e){if(e.isIntersecting){var anim=getComputedStyle(e.target).getPropertyValue("--score-scroll-animation").trim();e.target.style.opacity="1";if(anim)e.target.style.animation=anim;if(cfg.indexOf("once:0")===-1)custom.unobserve(e.target)}else if(cfg.indexOf("once:0")!==-1){e.target.style.opacity="0";e.target.style.animation="none"}})},{threshold:threshold});custom.observe(el)}else{io.observe(el)}})})();
        """

    /// Delegated event handler for `[data-code-copy]` buttons.
    ///
    /// Listens for clicks on any button with `data-code-copy` and copies the
    /// text content of the associated `<pre>` element (identified by
    /// `data-code-id`) to the clipboard.
    public static let codeCopyRuntime = """
        document.addEventListener("click",function(e){var b=e.target.closest("[data-code-copy]");if(!b)return;var txt;var id=b.getAttribute("data-code-id");if(id){var src=document.getElementById(id);if(src)txt=src.textContent}else{var g=b.closest("[data-tab-group]");if(g){var inputs=g.querySelectorAll("input[type=radio]");var idx=0;for(var i=0;i<inputs.length;i++){if(inputs[i].checked){idx=i;break}}var p=g.querySelectorAll("[data-tab-panel]")[idx];var s=p&&p.querySelector("[data-tab-source]");if(s)txt=s.textContent}}if(!txt)return;navigator.clipboard.writeText(txt).then(function(){b.textContent="Copied!";setTimeout(function(){b.textContent="Copy"},1500)})});
        """

    /// Delegated initializer for `[data-tab-group]` components.
    ///
    /// Wires up radio input change listeners to toggle copy-button visibility
    /// based on whether the active tab panel has a `[data-tab-source]` element.
    public static let tabGroupRuntime = """
        (function(){document.querySelectorAll("[data-tab-group]").forEach(function(g){var btn=g.querySelector("[data-code-copy]");if(!btn)return;var inputs=g.querySelectorAll("input[type=radio]");function u(){var idx=0;for(var i=0;i<inputs.length;i++){if(inputs[i].checked){idx=i;break}}var p=g.querySelectorAll("[data-tab-panel]")[idx];btn.style.display=p&&p.querySelector("[data-tab-source]")?"":"none"}for(var i=0;i<inputs.length;i++)inputs[i].addEventListener("change",u);u()})})();
        """

    /// IndexedDB cache and offline sync queue runtime for local-first queries.
    ///
    /// Uses a single IndexedDB database (`score_cache`) with two object stores:
    /// - `cache`: key-value store keyed by `endpoint + "/" + id`
    /// - `sync_queue`: FIFO queue of pending mutations with auto-increment keys
    ///
    /// The runtime provides `_scoreDB` for cache operations and `_scoreSyncQ`
    /// for queuing and processing offline mutations. Online/offline listeners
    /// trigger automatic sync queue processing.
    public static let localFirstRuntime = """
        const _scoreDB=(()=>{let db;const DB="score_cache";const open=()=>new Promise((res,rej)=>{if(db)return res(db);const r=indexedDB.open(DB,1);r.onupgradeneeded=e=>{const d=e.target.result;if(!d.objectStoreNames.contains("cache"))d.createObjectStore("cache",{keyPath:"_ck"});if(!d.objectStoreNames.contains("sync_queue"))d.createObjectStore("sync_queue",{autoIncrement:true})};r.onsuccess=e=>{db=e.target.result;res(db)};r.onerror=e=>rej(e)});const tx=(s,m)=>open().then(d=>d.transaction(s,m).objectStore(s));const req=r=>new Promise((res,rej)=>{r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});return{getAll(ep){return tx("cache","readonly").then(s=>req(s.getAll())).then(rows=>rows.filter(r=>r._ck.startsWith(ep+"/")).map(r=>{const c={...r};delete c._ck;return c}))},putAll(ep,items){return tx("cache","readwrite").then(s=>{items.forEach(i=>s.put({...i,_ck:ep+"/"+i.id}));return req(s.transaction)})},put(ep,item){return tx("cache","readwrite").then(s=>req(s.put({...item,_ck:ep+"/"+item.id})))},remove(ep,id){return tx("cache","readwrite").then(s=>req(s.delete(ep+"/"+id)))},clear(ep){return tx("cache","readwrite").then(s=>{return new Promise((res,rej)=>{const c=s.openCursor();c.onsuccess=e=>{const cur=e.target.result;if(cur){if(cur.key.startsWith(ep+"/"))cur.delete();cur.continue()}else res()};c.onerror=()=>rej(c.error)})})}}})();
        const _scoreSyncQ=(()=>{const tx=m=>_scoreDB.open?_scoreDB.open():Promise.resolve().then(()=>{const r=indexedDB.open("score_cache",1);return new Promise((res,rej)=>{r.onsuccess=e=>res(e.target.result);r.onerror=e=>rej(e)})}).then(d=>d.transaction("sync_queue",m).objectStore("sync_queue"));const req=r=>new Promise((res,rej)=>{r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});const MAX_RETRIES=5;let processing=false;return{add(entry){return tx("readwrite").then(s=>req(s.add({...entry,_retries:0})))},process(){if(processing||!navigator.onLine)return Promise.resolve();processing=true;return tx("readonly").then(s=>new Promise((res,rej)=>{const entries=[];const c=s.openCursor();c.onsuccess=e=>{const cur=e.target.result;if(cur){entries.push({key:cur.key,...cur.value});cur.continue()}else res(entries)};c.onerror=()=>rej(c.error)})).then(async entries=>{for(const e of entries){try{const opts={method:e.m,credentials:"same-origin"};if(e.b)opts.headers={"Content-Type":"application/json"};if(e.b)opts.body=JSON.stringify(e.b);const r=await fetch(e.ep,opts);if(!r.ok)throw new Error(r.statusText);const s=await tx("readwrite");await req(s.delete(e.key))}catch(err){const retries=(e._retries||0)+1;const s=await tx("readwrite");if(retries>=MAX_RETRIES){await req(s.delete(e.key))}else{await req(s.put({...e,_retries:retries},e.key));const delay=Math.min(1000*Math.pow(2,retries),30000);await new Promise(r=>setTimeout(r,delay))}break}}}).finally(()=>{processing=false})}}})();
        addEventListener("online",()=>_scoreSyncQ.process());
        """

    // MARK: - Emission

    /// The result of analyzing a page's reactive content.
    public struct EmissionResult: Sendable {
        /// JavaScript for page-level declarations (outside any stateful `Component`).
        public let pageLevelJS: String
        /// Per-`Component` JavaScript blocks, each wrapped in `{ ... }`.
        public let scopeBlocks: [String]
        /// Whether this page requires the Score signals runtime.
        public let needsRuntime: Bool
        /// Whether this page requires the local-first IndexedDB runtime.
        public let needsLocalFirstRuntime: Bool
        /// Page-level state properties.
        public let pageStates: [StateInfo]
        /// Page-level computed properties.
        public let pageComputeds: [ComputedInfo]
        /// Page-level actions.
        public let pageActions: [ActionInfo]
        /// Per-`Component` scope metadata.
        public let componentScopes: [ComponentScope]

        /// Combined page JavaScript for inline use or backward compatibility.
        public var pageJS: String {
            var js = pageLevelJS
            for block in scopeBlocks { js.append(block) }
            return js
        }
    }

    /// Analyzes a page and returns its reactive JavaScript separately from
    /// the shared runtime. Use this when externalizing scripts to files.
    public static func emitPageScript(page: some Page) -> EmissionResult {
        let pageStates = extractStates(from: page)
        let pageComputeds = extractComputeds(from: page)
        let pageActions = extractActions(from: page)
        let pageMirror = Mirror(reflecting: page)
        let pageQueries = extractQueriesFromMirror(pageMirror)
        let pageGroupedStates = extractGroupedStatesFromMirror(pageMirror)

        let (rawScopes, pageLevelBindings, pageLevelReactive) = extractComponentScopes(from: page.body)
        let componentScopes = mergeComponentScopes(rawScopes)

        let hasPageLevel =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageActions.isEmpty || !pageQueries.isEmpty
            || !pageGroupedStates.isEmpty
            || !pageLevelBindings.isEmpty || !pageLevelReactive.isEmpty
        let hasElementLevel = !componentScopes.isEmpty

        guard hasPageLevel || hasElementLevel else {
            return EmissionResult(
                pageLevelJS: "", scopeBlocks: [], needsRuntime: false, needsLocalFirstRuntime: false,
                pageStates: [], pageComputeds: [], pageActions: [], componentScopes: []
            )
        }

        let needsRuntime =
            !pageStates.isEmpty || !pageComputeds.isEmpty || !pageQueries.isEmpty || !pageGroupedStates.isEmpty
            || !pageLevelReactive.isEmpty
            || componentScopes.contains(where: {
                !$0.states.isEmpty || !$0.computeds.isEmpty || !$0.queries.isEmpty || !$0.reactiveBindings.isEmpty
            })

        let needsLocalFirst =
            pageQueries.contains(where: { $0.isLocalFirst })
            || componentScopes.contains(where: { $0.queries.contains(where: { $0.isLocalFirst }) })

        let devMode = Environment.current == .development

        // Hoist persisted states that appear in multiple scopes to page level
        // so they are declared once and shared (e.g. isDark theme toggle).
        var hoistedStates: [StateInfo] = []
        var hoistedStorageKeys: Set<String> = []
        var mutableScopes = componentScopes

        var storageKeyCounts: [String: Int] = [:]
        for scope in mutableScopes {
            for state in scope.states where !state.storageKey.isEmpty {
                storageKeyCounts[state.storageKey, default: 0] += 1
            }
        }
        for (key, count) in storageKeyCounts where count > 1 {
            hoistedStorageKeys.insert(key)
        }
        if !hoistedStorageKeys.isEmpty {
            for i in mutableScopes.indices {
                var lifted: [StateInfo] = []
                mutableScopes[i].states.removeAll { state in
                    if hoistedStorageKeys.contains(state.storageKey) {
                        lifted.append(state)
                        return true
                    }
                    return false
                }
                for state in lifted where !hoistedStates.contains(where: { $0.storageKey == state.storageKey }) {
                    hoistedStates.append(state)
                }
            }
        }

        var pageLevelJS = ""
        var bindingOffset = 0
        var reactiveOffset = 0

        emitDeclarations(
            states: pageStates, computeds: pageComputeds,
            actions: pageActions, queries: pageQueries,
            groupedStates: pageGroupedStates, bindings: pageLevelBindings,
            reactiveBindings: pageLevelReactive,
            bindingOffset: &bindingOffset, reactiveOffset: &reactiveOffset,
            isDevMode: devMode, into: &pageLevelJS
        )

        var scopeBlocks: [String] = []

        // Emit hoisted states as a standalone scope block so the chunking
        // system places them in shared.js (available to all pages) rather
        // than duplicating them into each per-page file.
        if !hoistedStates.isEmpty {
            var hoistBlock = ""
            emitDeclarations(
                states: hoistedStates, computeds: [], actions: [],
                bindings: [], reactiveBindings: [],
                bindingOffset: &bindingOffset, reactiveOffset: &reactiveOffset,
                isDevMode: devMode, into: &hoistBlock
            )
            if !hoistBlock.isEmpty {
                scopeBlocks.append(hoistBlock)
            }
        }
        for scope in mutableScopes {
            let cssScopeName = CSSNaming.className(from: scope.name)
            var block = "{\n"
            emitDeclarations(
                states: scope.states, computeds: scope.computeds,
                actions: scope.actions, queries: scope.queries, bindings: scope.bindings,
                reactiveBindings: scope.reactiveBindings,
                bindingOffset: &bindingOffset, reactiveOffset: &reactiveOffset,
                scopeName: cssScopeName,
                isDevMode: devMode, into: &block
            )
            block.append("}\n")
            scopeBlocks.append(block)
        }

        return EmissionResult(
            pageLevelJS: pageLevelJS, scopeBlocks: scopeBlocks, needsRuntime: needsRuntime,
            needsLocalFirstRuntime: needsLocalFirst,
            pageStates: pageStates, pageComputeds: pageComputeds, pageActions: pageActions,
            componentScopes: componentScopes
        )
    }

    /// Merges component scopes that share the same `mergeKey` so that
    /// state, computed, and action declarations are emitted once while
    /// event bindings from all instances are wired to the shared scope.
    /// Components without a `scopeKey` each receive a unique merge key
    /// and therefore remain independent.
    private static func mergeComponentScopes(_ scopes: [ComponentScope]) -> [ComponentScope] {
        var seen: [String: Int] = [:]
        var merged: [ComponentScope] = []

        for scope in scopes {
            if let index = seen[scope.mergeKey] {
                merged[index].bindings.append(contentsOf: scope.bindings)
                merged[index].reactiveBindings.append(contentsOf: scope.reactiveBindings)
            } else {
                seen[scope.mergeKey] = merged.count
                merged.append(scope)
            }
        }

        return merged
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
        if result.needsLocalFirstRuntime {
            js.append(localFirstRuntime)
        }
        js.append(result.pageJS)
        return "<script>\n\(js)</script>"
    }

    /// Emits `const`, `function`, `addEventListener`, and `Signal.effect` lines
    /// for a set of declarations, advancing binding offsets as they are emitted.
    private static func emitDeclarations(
        states: [StateInfo], computeds: [ComputedInfo],
        actions: [ActionInfo], queries: [QueryInfo] = [],
        groupedStates: [GroupedStateInfo] = [],
        bindings: [EventBinding],
        reactiveBindings: [ReactiveBinding] = [],
        bindingOffset: inout Int, reactiveOffset: inout Int,
        scopeName: String? = nil,
        isDevMode: Bool = false, into js: inout String
    ) {
        for grouped in groupedStates {
            for field in grouped.fields {
                js.append("const \(grouped.name)_\(field.name) = new Signal.State(\(field.initialValue));\n")
            }
            let resetBody = grouped.fields.map { "\(grouped.name)_\($0.name).set(\($0.initialValue))" }.joined(separator: "; ")
            js.append("function \(grouped.name)_reset() { \(resetBody) }\n")
        }
        for state in states {
            if state.storageKey.isEmpty {
                js.append("const \(state.name) = new Signal.State(\(state.initialValue));\n")
            } else if state.isTheme {
                js.append(
                    "const \(state.name) = new Signal.State((()=>{var v=localStorage.getItem(\"\(state.storageKey)\");if(v!=null){var p=JSON.parse(v);return typeof p===\"boolean\"?p:p===\"dark\"}return window.matchMedia&&window.matchMedia(\"(prefers-color-scheme: dark)\").matches?true:\(state.initialValue)})());\n"
                )
            } else {
                js.append(
                    "const \(state.name) = new Signal.State((()=>{var v=localStorage.getItem(\"\(state.storageKey)\");return v!==null?JSON.parse(v):\(state.initialValue)})());\n")
            }
        }
        for query in queries {
            let n = query.name
            let ep = query.endpoint
            js.append("const \(n) = new Signal.State([]);\n")
            js.append("const \(n)_isLoading = new Signal.State(true);\n")
            js.append("const \(n)_isFailed = new Signal.State(false);\n")
            js.append("const \(n)_error = new Signal.State(\"\");\n")
            if query.isLocalFirst {
                // Local-first: cache in IndexedDB, optimistic CRUD, offline sync queue
                js.append("const \(n)_isSyncing = new Signal.State(false);\n")
                js.append("const \(n)_isOffline = new Signal.State(!navigator.onLine);\n")
                js.append("addEventListener(\"online\",()=>\(n)_isOffline.set(false));addEventListener(\"offline\",()=>\(n)_isOffline.set(true));\n")
                // Fetch: serve from cache immediately, then sync from server
                js.append(
                    "async function \(n)_fetch(){var cached=await _scoreDB.getAll(\"\(ep)\");if(cached.length){\(n).set(cached);\(n)_isLoading.set(false)}try{var r=await fetch(\"\(ep)\",{credentials:\"same-origin\"});if(!r.ok)throw new Error(r.statusText);var data=await r.json();\(n).set(data);await _scoreDB.putAll(\"\(ep)\",data)}catch(e){if(!cached.length){\(n)_isFailed.set(true);\(n)_error.set(e.message)}}finally{\(n)_isLoading.set(false)}}\n"
                )
                // Create: optimistic local insert + queue sync
                js.append(
                    "async function \(n)_create(d){var v={};for(var k in d){var s=typeof d[k]===\"string\"?d[k].trim():d[k];if(s===\"\"||s==null)return;v[k]=s}var t={...v,id:v.id||crypto.randomUUID()};var prev=\(n).get();\(n).set([...prev,t]);_scoreDB.put(\"\(ep)\",t);\(n)_isSyncing.set(true);try{await _scoreSyncQ.add({ep:\"\(ep)\",m:\"POST\",b:t});await _scoreSyncQ.process();await \(n)_fetch()}catch(e){}finally{\(n)_isSyncing.set(false)}}\n"
                )
                js.append("function \(n)_read(){\(n)_fetch()}\n")
                // Update: optimistic local patch + queue sync
                js.append(
                    "async function \(n)_update(id,d){var t={...d,id:id};\(n).set(\(n).get().map(x=>x.id===id?{...x,...t}:x));_scoreDB.put(\"\(ep)\",t);\(n)_isSyncing.set(true);try{await _scoreSyncQ.add({ep:\"\(ep)/\"+id,m:\"PUT\",b:t});await _scoreSyncQ.process();await \(n)_fetch()}catch(e){}finally{\(n)_isSyncing.set(false)}}\n"
                )
                // Delete: optimistic local remove + queue sync
                js.append(
                    "async function \(n)_delete(id){\(n).set(\(n).get().filter(x=>x.id!==id));_scoreDB.remove(\"\(ep)\",id);\(n)_isSyncing.set(true);try{await _scoreSyncQ.add({ep:\"\(ep)/\"+id,m:\"DELETE\",b:null});await _scoreSyncQ.process();await \(n)_fetch()}catch(e){}finally{\(n)_isSyncing.set(false)}}\n"
                )
            } else {
                // Server-only: original fetch-based CRUD
                js.append(
                    "async function \(n)_fetch(){\(n)_isLoading.set(true);\(n)_isFailed.set(false);\(n)_error.set(\"\");try{var r=await fetch(\"\(ep)\",{credentials:\"same-origin\"});if(!r.ok)throw new Error(r.statusText);\(n).set(await r.json())}catch(e){\(n)_isFailed.set(true);\(n)_error.set(e.message)}finally{\(n)_isLoading.set(false)}}\n"
                )
                js.append(
                    "function \(n)_create(d){var v={};for(var k in d){var s=typeof d[k]===\"string\"?d[k].trim():d[k];if(s===\"\"||s==null)return;v[k]=s}fetch(\"\(ep)\",{method:\"POST\",credentials:\"same-origin\",headers:{\"Content-Type\":\"application/json\"},body:JSON.stringify(v)}).then(()=>\(n)_fetch())}\n"
                )
                js.append("function \(n)_read(){\(n)_fetch()}\n")
                js.append(
                    "function \(n)_update(id,d){fetch(\"\(ep)/\"+id,{method:\"PUT\",credentials:\"same-origin\",headers:{\"Content-Type\":\"application/json\"},body:JSON.stringify(d)}).then(()=>\(n)_fetch())}\n"
                )
                js.append(
                    "function \(n)_delete(id){fetch(\"\(ep)/\"+id,{method:\"DELETE\",credentials:\"same-origin\"}).then(()=>\(n)_fetch())}\n"
                )
            }
            js.append("\(n)_fetch();\n")
            if let interval = query.pollInterval, interval > 0 {
                js.append("setInterval(\(n)_fetch,\(interval * 1000));\n")
            }
        }
        for computed in computeds {
            if computed.body.isEmpty {
                js.append("const \(computed.name) = new Signal.Computed(() => \(computed.name));\n")
            } else {
                js.append("const \(computed.name) = new Signal.Computed(() => \(computed.body));\n")
            }
        }
        if isDevMode && (!states.isEmpty || !computeds.isEmpty) {
            js.append("var __sd=(window.__SCORE_DEV__=window.__SCORE_DEV__||{}).signals=window.__SCORE_DEV__.signals||{};\n")
            for state in states {
                js.append("__sd.\(state.name)=\(state.name);\n")
            }
            for computed in computeds {
                js.append("__sd.\(computed.name)=\(computed.name);\n")
            }
        }
        for action in actions {
            let params = action.parameters.isEmpty ? "event" : action.parameters.joined(separator: ", ")
            if action.body.isEmpty {
                js.append("function \(action.name)(\(params)) {}\n")
            } else {
                js.append("function \(action.name)(\(params)) { \(action.body) }\n")
            }
        }
        for binding in bindings {
            let actionScope = scopeName ?? "page"
            let actionKey = "\(actionScope):\(binding.handler)"
            let selector = "document.querySelectorAll(\"[data-action=\\\"\(actionKey)\\\"]\")"
            if !binding.args.isEmpty {
                let escapedArgs = binding.args.map { "\"\($0.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\"" }.joined(separator: ",")
                if binding.preventDefault {
                    js.append("\(selector).forEach(function(el){el.addEventListener(\"\(binding.event)\",(e)=>{e.preventDefault();\(binding.handler)(\(escapedArgs))})});\n")
                } else {
                    js.append("\(selector).forEach(function(el){el.addEventListener(\"\(binding.event)\",()=>{\(binding.handler)(\(escapedArgs))})});\n")
                }
            } else if binding.preventDefault {
                js.append("\(selector).forEach(function(el){el.addEventListener(\"\(binding.event)\",(e)=>{e.preventDefault();\(binding.handler)(e)})});\n")
            } else {
                js.append("\(selector).forEach(function(el){el.addEventListener(\"\(binding.event)\", \(binding.handler))});\n")
            }
            bindingOffset += 1
        }
        for state in states where !state.storageKey.isEmpty {
            js.append("(function(){var _i=1;Signal.effect(()=>{var v=\(state.name).get();if(_i){_i=0;return}localStorage.setItem(\"\(state.storageKey)\",JSON.stringify(v))")
            if state.isTheme {
                js.append(";document.documentElement.setAttribute(\"data-theme\",v?\"dark\":\"light\")")
            }
            js.append("})})();\n")
        }
        for reactive in reactiveBindings {
            switch reactive.kind {
            case .visibility(let stateName):
                let index = reactive.documentIndex >= 0 ? reactive.documentIndex : reactiveOffset
                let selector = "document.querySelector(\"[data-r=\\\"\(index)\\\"]\")"
                js.append("Signal.effect(() => { var h=!\(stateName).get();\(selector).classList.toggle(\"score-hidden\",h);\(selector).setAttribute(\"aria-hidden\",h?\"true\":\"false\"); });\n")
                reactiveOffset += 1
            case .text(let bindingName):
                js.append(
                    "Signal.effect(() => { document.querySelector('[data-bind=\"\(bindingName)\"]').textContent = \(bindingName).get(); });\n"
                )
            case .inputValue(let stateName):
                js.append(
                    "(function(){var el=document.querySelector('[data-bind-value=\"\(stateName)\"]');el.addEventListener(\"input\",(e)=>\(stateName).set(e.target.value));Signal.effect(()=>{if(document.activeElement!==el)el.value=\(stateName).get()})})();\n"
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
                    storageKey: descriptor.storageKey,
                    isTheme: descriptor.isTheme
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
            actions.append(ActionInfo(name: descriptor.name, body: descriptor.body, parameters: descriptor.parameters))
        }
        return actions
    }

    private static func extractQueriesFromMirror(_ mirror: Mirror) -> [QueryInfo] {
        var queries: [QueryInfo] = []
        for child in mirror.children {
            guard let descriptor = child.value as? QueryDescriptor else { continue }
            queries.append(
                QueryInfo(
                    name: descriptor.name,
                    endpoint: descriptor.endpoint,
                    pollInterval: descriptor.pollInterval,
                    isLocalFirst: descriptor.syncMode == .localFirst
                ))
        }
        return queries
    }

    /// Information about a grouped `@State` property (struct with per-field signals).
    public struct GroupedStateInfo: Sendable {
        public let name: String
        public let fields: [(name: String, initialValue: String)]
    }

    private static func extractGroupedStatesFromMirror(_ mirror: Mirror) -> [GroupedStateInfo] {
        var grouped: [GroupedStateInfo] = []
        for child in mirror.children {
            guard let descriptor = child.value as? GroupedStateDescriptor else { continue }
            grouped.append(GroupedStateInfo(name: descriptor.name, fields: descriptor.fields))
        }
        return grouped
    }

    package static func walkForComponents(
        _ node: some Node,
        states: inout [StateInfo],
        computeds: inout [ComputedInfo],
        actions: inout [ActionInfo]
    ) {
        if node is any Component {
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

        if !node.isLeafNode {
            walkForComponents(node.body, states: &states, computeds: &computeds, actions: &actions)
        }
    }

    package static func walkForEvents(_ node: some Node, into bindings: inout [EventBinding]) {
        if node is any Component { return }

        if let modified = node as? any ModifiedNodeAccessible {
            for modifier in modified.accessibleModifiers {
                if let eventMod = modifier as? EventBindingModifier {
                    bindings.append(
                        EventBinding(
                            event: eventMod.event.name,
                            handler: eventMod.handler,
                            args: eventMod.args,
                            preventDefault: eventMod.preventDefault
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

        if !node.isLeafNode {
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
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
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
        JSEmitter.walkForComponents(content, states: &states, computeds: &computeds, actions: &actions)
    }
    func walkContentForScopes(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        JSEmitter.walkForScopes(
            content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    func walkContentForReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}

/// Protocol for primitive nodes to walk their children for event bindings.
package protocol JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding])
    func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    )
    func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    )
    func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding])
}

/// Protocol for container nodes that walk a single `content` child.
package protocol JSContentWalkable: JSEventWalkable {
    associatedtype Content: Node
    var content: Content { get }
}

extension JSContentWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForComponents(content, states: &states, computeds: &computeds, actions: &actions)
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        JSEmitter.walkForScopes(
            content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}

/// Protocol for leaf nodes with no children to walk.
package protocol JSLeafWalkable: JSEventWalkable {}

extension JSLeafWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {}
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {}
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {}
}

// Builder nodes
extension TupleNode: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        repeat JSEmitter.walkForEvents(each children, into: &bindings)
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        repeat JSEmitter.walkForComponents(each children, states: &states, computeds: &computeds, actions: &actions)
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        repeat JSEmitter.walkForScopes(
            each children, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        repeat JSEmitter.walkForReactiveBindings(each children, into: &bindings)
    }
}

extension ConditionalNode: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForEvents(node, into: &bindings)
        case .second(let node): JSEmitter.walkForEvents(node, into: &bindings)
        }
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        switch storage {
        case .first(let node): JSEmitter.walkForComponents(node, states: &states, computeds: &computeds, actions: &actions)
        case .second(let node): JSEmitter.walkForComponents(node, states: &states, computeds: &computeds, actions: &actions)
        }
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        switch storage {
        case .first(let node):
            JSEmitter.walkForScopes(
                node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        case .second(let node):
            JSEmitter.walkForScopes(
                node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForReactiveBindings(node, into: &bindings)
        case .second(let node): JSEmitter.walkForReactiveBindings(node, into: &bindings)
        }
    }
}

extension OptionalNode: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        if let node = wrapped { JSEmitter.walkForEvents(node, into: &bindings) }
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        if let node = wrapped { JSEmitter.walkForComponents(node, states: &states, computeds: &computeds, actions: &actions) }
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        if let node = wrapped {
            JSEmitter.walkForScopes(
                node, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        if let node = wrapped { JSEmitter.walkForReactiveBindings(node, into: &bindings) }
    }
}

extension ForEachNode: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for item in data { JSEmitter.walkForEvents(content(item), into: &bindings) }
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        for item in data { JSEmitter.walkForComponents(content(item), states: &states, computeds: &computeds, actions: &actions) }
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        for item in data {
            JSEmitter.walkForScopes(
                content(item), scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        for item in data { JSEmitter.walkForReactiveBindings(content(item), into: &bindings) }
    }
}

extension ArrayNode: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for child in children { JSEmitter.walkForEvents(child, into: &bindings) }
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        for child in children { JSEmitter.walkForComponents(child, states: &states, computeds: &computeds, actions: &actions) }
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        for child in children {
            JSEmitter.walkForScopes(
                child, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
                eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
            )
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        for child in children { JSEmitter.walkForReactiveBindings(child, into: &bindings) }
    }
}

extension Content: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(wrapped, into: &bindings)
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForComponents(wrapped, states: &states, computeds: &computeds, actions: &actions)
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        JSEmitter.walkForScopes(
            wrapped, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(wrapped, into: &bindings)
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
extension Form: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        if let ref = actionRefName {
            bindings.append(JSEmitter.EventBinding(event: "submit", handler: ref, preventDefault: true))
        }
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForComponents(content, states: &states, computeds: &computeds, actions: &actions)
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        if let ref = actionRefName {
            var binding = JSEmitter.EventBinding(event: "submit", handler: ref, preventDefault: true)
            binding.documentIndex = eventCounter
            eventCounter += 1
            pageLevelBindings.append(binding)
        }
        JSEmitter.walkForScopes(
            content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        JSEmitter.walkForReactiveBindings(content, into: &bindings)
    }
}
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
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(summary, into: &bindings)
        JSEmitter.walkForEvents(content, into: &bindings)
    }
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {
        JSEmitter.walkForComponents(summary, states: &states, computeds: &computeds, actions: &actions)
        JSEmitter.walkForComponents(content, states: &states, computeds: &computeds, actions: &actions)
    }
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        JSEmitter.walkForScopes(
            summary, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
        JSEmitter.walkForScopes(
            content, scopes: &scopes, pageLevelBindings: &pageLevelBindings, pageLevelReactive: &pageLevelReactive,
            eventCounter: &eventCounter, reactiveCounter: &reactiveCounter
        )
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
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
extension Input: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {}
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        if let name = reactiveBindingName {
            var binding = JSEmitter.ReactiveBinding(kind: .inputValue(stateName: name))
            binding.documentIndex = reactiveCounter
            reactiveCounter += 1
            pageLevelReactive.append(binding)
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        if let name = reactiveBindingName {
            bindings.append(.init(kind: .inputValue(stateName: name)))
        }
    }
}
extension TextArea: JSEventWalkable {
    package func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
    package func walkForJSElements(
        states: inout [JSEmitter.StateInfo],
        computeds: inout [JSEmitter.ComputedInfo],
        actions: inout [JSEmitter.ActionInfo]
    ) {}
    package func walkForJSScoped(
        scopes: inout [JSEmitter.ComponentScope],
        pageLevelBindings: inout [JSEmitter.EventBinding],
        pageLevelReactive: inout [JSEmitter.ReactiveBinding],
        eventCounter: inout Int,
        reactiveCounter: inout Int
    ) {
        if let name = reactiveBindingName {
            var binding = JSEmitter.ReactiveBinding(kind: .inputValue(stateName: name))
            binding.documentIndex = reactiveCounter
            reactiveCounter += 1
            pageLevelReactive.append(binding)
        }
    }
    package func walkForJSReactive(into bindings: inout [JSEmitter.ReactiveBinding]) {
        if let name = reactiveBindingName {
            bindings.append(.init(kind: .inputValue(stateName: name)))
        }
    }
}
extension Progress: JSLeafWalkable {}
extension Meter: JSLeafWalkable {}
extension Source: JSLeafWalkable {}
extension Track: JSLeafWalkable {}
extension TableColumn: JSLeafWalkable {}
