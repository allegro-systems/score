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

    /// Information about an `@Action` function extracted via Mirror.
    public struct ActionInfo: Sendable {
        public let name: String
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
            guard let marker = child.value as? any StateIdentifying else { continue }
            let name = cleanLabel(child.label)
            let initialValue = formatInitialValue(child.value)
            states.append(
                StateInfo(
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
            guard child.value is any ComputedIdentifying else { continue }
            computeds.append(ComputedInfo(name: cleanLabel(child.label)))
        }
        return computeds
    }

    /// Extracts all `@Action` functions from a page instance.
    ///
    /// The `@Action` macro generates `_action_<name>` peer properties of type
    /// `ActionDescriptor`. This method finds them via Mirror reflection.
    public static func extractActions(from page: some Page) -> [ActionInfo] {
        let mirror = Mirror(reflecting: page)
        var actions: [ActionInfo] = []
        for child in mirror.children {
            guard let descriptor = child.value as? ActionDescriptor else { continue }
            actions.append(ActionInfo(name: descriptor.name))
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
            js.append("function \(action.name)(event) {}\n")
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

        // Walk primitive node types
        if let walkable = node as? any JSEventWalkable {
            walkable.walkForJSEvents(into: &bindings)
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
protocol ModifiedNodeAccessible {
    var accessibleModifiers: [any ModifierValue] { get }
    func walkContent(into bindings: inout [JSEmitter.EventBinding])
}

extension ModifiedNode: ModifiedNodeAccessible {
    var accessibleModifiers: [any ModifierValue] { modifiers }
    func walkContent(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(content, into: &bindings)
    }
}

/// Internal protocol for primitive nodes to walk their children for event bindings.
protocol JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding])
}

// Builder nodes
extension TupleNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        repeat JSEmitter.walkForEvents(each children, into: &bindings)
    }
}

extension ConditionalNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        switch storage {
        case .first(let node): JSEmitter.walkForEvents(node, into: &bindings)
        case .second(let node): JSEmitter.walkForEvents(node, into: &bindings)
        }
    }
}

extension OptionalNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        if let node = wrapped { JSEmitter.walkForEvents(node, into: &bindings) }
    }
}

extension ForEachNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for item in data { JSEmitter.walkForEvents(content(item), into: &bindings) }
    }
}

extension ArrayNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        for child in children { JSEmitter.walkForEvents(child, into: &bindings) }
    }
}

extension EmptyNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

extension TextNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

extension RawTextNode: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}

// Container domain nodes — walk content
extension Heading: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Paragraph: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Text: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Strong: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Emphasis: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Small: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Mark: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Code: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Preformatted: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Blockquote: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Address: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Stack: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Main: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Section: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Article: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Header: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Footer: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Aside: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Navigation: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Group: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Link: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Button: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Form: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Label: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Select: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Option: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension OptionGroup: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Fieldset: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Legend: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Output: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DataList: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Dialog: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Menu: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Summary: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Details: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {
        JSEmitter.walkForEvents(summary, into: &bindings)
        JSEmitter.walkForEvents(content, into: &bindings)
    }
}
extension UnorderedList: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension OrderedList: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension ListItem: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionList: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionTerm: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension DescriptionDetails: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Table: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableCaption: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableHead: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableBody: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableFooter: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableRow: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableHeaderCell: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableCell: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension TableColumnGroup: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Figure: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension FigureCaption: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Audio: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Video: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Picture: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}
extension Canvas: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) { JSEmitter.walkForEvents(content, into: &bindings) }
}

// Leaf nodes
extension HorizontalRule: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension LineBreak: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Image: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Input: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension TextArea: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Progress: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Meter: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Source: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension Track: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
extension TableColumn: JSEventWalkable {
    func walkForJSEvents(into bindings: inout [JSEmitter.EventBinding]) {}
}
