import ScoreCore

/// Extracts reactive bindings from a `Page` and emits client-side JavaScript.
public struct JSEmitter: Sendable {

    /// Information about a `@State` property extracted via Mirror.
    public struct StateInfo: Sendable {
        public let name: String
        public let initialValue: String
        public let effect: String
    }

    /// Information about a `@Computed` property extracted via Mirror.
    public struct ComputedInfo: Sendable {
        public let name: String
    }

    /// Information about an `@Action` property extracted via Mirror.
    public struct ActionInfo: Sendable {
        public let name: String
        public let jsBody: String
    }

    /// Information about an event binding extracted from a node tree.
    public struct EventBinding: Sendable {
        public let event: String
        public let handler: String
    }

    private init() {}

    // MARK: - Extraction

    /// Extracts all `@State` properties from a page instance.
    public static func extractStates(from page: some Page) -> [StateInfo] {
        let mirror = Mirror(reflecting: page)
        var states: [StateInfo] = []
        for child in mirror.children {
            guard let marker = child.value as? any _StateMarker else { continue }
            let name = cleanLabel(child.label)
            let initialValue = formatInitialValue(child.value)
            states.append(StateInfo(
                name: name,
                initialValue: initialValue,
                effect: marker.stateJSEffect
            ))
        }
        return states
    }

    /// Extracts all `@Computed` properties from a page instance.
    public static func extractComputeds(from page: some Page) -> [ComputedInfo] {
        let mirror = Mirror(reflecting: page)
        var computeds: [ComputedInfo] = []
        for child in mirror.children {
            guard child.value is any _ComputedMarker else { continue }
            computeds.append(ComputedInfo(name: cleanLabel(child.label)))
        }
        return computeds
    }

    /// Extracts all `@Action` properties from a page instance.
    public static func extractActions(from page: some Page) -> [ActionInfo] {
        let mirror = Mirror(reflecting: page)
        var actions: [ActionInfo] = []
        for child in mirror.children {
            guard let action = child.value as? Action else { continue }
            actions.append(ActionInfo(
                name: cleanLabel(child.label),
                jsBody: action.jsBody
            ))
        }
        return actions
    }

    /// Extracts all event bindings from a node tree.
    public static func extractEventBindings(from node: some Node) -> [EventBinding] {
        var bindings: [EventBinding] = []
        walkForEvents(node, into: &bindings)
        return bindings
    }

    // MARK: - Emission

    /// Emits a `<script>` tag for a page, or an empty string if the page
    /// has no reactive properties or event bindings.
    public static func emit(page: some Page, environment: Environment) -> String {
        let states = extractStates(from: page)
        let computeds = extractComputeds(from: page)
        let actions = extractActions(from: page)
        let bindings = extractEventBindings(from: page.body)

        guard !states.isEmpty || !computeds.isEmpty || !actions.isEmpty || !bindings.isEmpty else {
            return ""
        }

        var js = ""

        // State declarations
        for state in states {
            js.append("const \(state.name) = Score.state(\(state.initialValue));\n")
        }

        // Computed declarations
        for computed in computeds {
            js.append("const \(computed.name) = Score.computed(() => \(computed.name));\n")
        }

        // Action function declarations
        for action in actions {
            js.append("function \(action.name)(event) { \(action.jsBody) }\n")
        }

        // Event bindings
        for (i, binding) in bindings.enumerated() {
            if environment == .development {
                js.append("document.querySelector(\"[data-s=\\\"\(i)\\\"]\").addEventListener(\"\(binding.event)\", \(binding.handler));\n")
            } else {
                js.append("document.querySelector(\"[data-s=\\\"\(i)\\\"]\").addEventListener(\"\(binding.event)\", \(binding.handler));\n")
            }
        }

        // Effects
        for state in states where !state.effect.isEmpty {
            js.append("Score.effect(() => { \(state.effect) });\n")
        }

        return "<script>\n\(js)</script>"
    }

    // MARK: - Helpers

    private static func cleanLabel(_ label: String?) -> String {
        guard var l = label else { return "" }
        if l.hasPrefix("_") { l = String(l.dropFirst()) }
        return l
    }

    private static func formatInitialValue(_ stateWrapper: Any) -> String {
        let mirror = Mirror(reflecting: stateWrapper)
        guard let wrappedChild = mirror.children.first(where: { $0.label == "wrappedValue" }) else {
            return "undefined"
        }
        let value = wrappedChild.value
        switch value {
        case let v as Int: return "\(v)"
        case let v as Double:
            return v.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(v))" : "\(v)"
        case let v as Bool: return v ? "true" : "false"
        case let v as String: return "\"\(v)\""
        default: return "\(value)"
        }
    }

    static func walkForEvents(_ node: some Node, into bindings: inout [EventBinding]) {
        // Check for modified node with event bindings
        if let modified = node as? any _ModifiedNodeAccess {
            for modifier in modified._modifiers {
                if let eventMod = modifier as? EventBindingModifier {
                    bindings.append(EventBinding(
                        event: eventMod.event.name,
                        handler: eventMod.handler
                    ))
                }
            }
            modified._walkContent(into: &bindings)
            return
        }

        // Walk primitive node types
        if let walkable = node as? any _JSEventWalkable {
            walkable._walkForJSEvents(into: &bindings)
            return
        }

        // Composite node — expand body
        if !(node.body is Never) {
            walkForEvents(node.body, into: &bindings)
        }
    }
}

// MARK: - Internal Protocols for Walking

/// Internal protocol for accessing ModifiedNode's modifiers and content.
protocol _ModifiedNodeAccess {
    var _modifiers: [any ModifierValue] { get }
    func _walkContent(into bindings: inout [JSEmitter.EventBinding])
}

extension ModifiedNode: _ModifiedNodeAccess {
    var _modifiers: [any ModifierValue] { modifiers }
    func _walkContent(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(content, into: &bindings)
    }
}

/// Internal protocol for primitive nodes to walk their children for event bindings.
protocol _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding])
}

// Builder nodes
extension TupleNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        repeat JSEmitter.walkForEvents(each children, into: &bindings)
    }
}

extension ConditionalNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForEvents(node, into: &bindings)
        case .second(let node): JSEmitter.walkForEvents(node, into: &bindings)
        }
    }
}

extension OptionalNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        if let node = wrapped { JSEmitter.walkForEvents(node, into: &bindings) }
    }
}

extension ForEachNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for item in data { JSEmitter.walkForEvents(content(item), into: &bindings) }
    }
}

extension ArrayNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for child in children { JSEmitter.walkForEvents(child, into: &bindings) }
    }
}

extension EmptyNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

extension TextNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

extension RawTextNode: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

// Container domain nodes — walk content
extension Heading: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Paragraph: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Text: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Strong: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Emphasis: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Small: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Mark: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Code: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Preformatted: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Blockquote: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Address: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Stack: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Main: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Section: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Article: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Header: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Footer: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Aside: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Navigation: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Group: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Link: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Button: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Form: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Label: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Select: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Option: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension OptionGroup: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Fieldset: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Legend: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Output: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DataList: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Dialog: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Menu: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Summary: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Details: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(summary, into: &bindings)
        JSEmitter.walkForEvents(content, into: &bindings)
    }
}
extension UnorderedList: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension OrderedList: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension ListItem: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionList: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionTerm: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionDetails: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Table: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableCaption: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableHead: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableBody: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableFooter: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableRow: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableHeaderCell: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableCell: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableColumnGroup: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Figure: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension FigureCaption: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Audio: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Video: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Picture: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Canvas: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}

// Leaf nodes
extension HorizontalRule: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension LineBreak: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Image: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Input: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension TextArea: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Progress: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Meter: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Source: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Track: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension TableColumn: _JSEventWalkable {
    func _walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
