import ScoreCore

/// Produces no HTML output.
extension EmptyNode: HTMLRenderable {
    /// Emits nothing.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {}
}

/// Renders escaped text content directly into the output stream.
extension TextNode: HTMLRenderable {
    /// Appends the text content with `<`, `>`, `&`, and `"` escaped.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        output.append(content.htmlEscaped)
    }
}

/// Renders raw content directly into the output stream without escaping.
extension RawTextNode: HTMLRenderable {
    /// Appends the raw content verbatim with no HTML escaping.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        output.append(content)
    }
}

/// Renders the wrapped content, injecting a CSS scope class and HTML
/// attributes when available.
extension ModifiedNode: HTMLRenderable {
    /// Renders the underlying content node wrapped in a scoped `<div>` when
    /// the renderer's class injector returns a class name or HTML attribute
    /// modifiers are present. Otherwise renders the content directly.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        let className = renderer.classInjector?(modifiers)
        let htmlAttrs = collectHTMLAttributes()
        let hasEventBindings = modifiers.contains { $0 is EventBindingModifier }

        if className != nil || !htmlAttrs.isEmpty || hasEventBindings {
            output.append("<div")

            // Inject data-s attribute for event binding targeting.
            if hasEventBindings {
                let eventIndex = renderer.context.nextEventIndex()
                output.append(" data-s=\"\(eventIndex)\"")
            }

            // Merge class attribute: scoped CSS class + user-supplied classes.
            var classValue = className ?? ""
            if let userClasses = htmlAttrs["class"] {
                if classValue.isEmpty {
                    classValue = userClasses
                } else {
                    classValue += " \(userClasses)"
                }
            }
            if !classValue.isEmpty {
                output.append(" class=\"\(classValue.attributeEscaped)\"")
            }
            // Emit remaining HTML attributes.
            for (name, value) in htmlAttrs where name != "class" {
                guard name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == ":" }) else { continue }
                output.append(" \(name)=\"\(value.attributeEscaped)\"")
            }
            output.append(">")
            renderer.write(content, to: &output)
            output.append("</div>")
        } else {
            renderer.write(content, to: &output)
        }
    }

    /// Collects all HTML attributes from `HTMLAttributeModifier` values in
    /// this node's modifier array, returning them as a lookup dictionary.
    ///
    /// When multiple modifiers set the same attribute, later values win
    /// (except for `class` which is space-concatenated).
    private func collectHTMLAttributes() -> [String: String] {
        var result: [String: String] = [:]
        for modifier in modifiers {
            guard let attrMod = modifier as? HTMLAttributeModifier else { continue }
            for attr in attrMod.attributes {
                if attr.name == "class", let existing = result["class"] {
                    result["class"] = existing + " " + attr.value
                } else {
                    result[attr.name] = attr.value
                }
            }
        }
        return result
    }
}

/// Renders all children in declaration order via parameter pack expansion.
extension TupleNode: HTMLRenderable {
    /// Emits each child using `repeat each children`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        repeat renderer.write(each children, to: &output)
    }
}

/// Renders the active branch of an `if`/`else` builder expression.
extension ConditionalNode: HTMLRenderable {
    /// Emits the `.first` or `.second` branch depending on which was chosen at build time.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        switch storage {
        case .first(let content): renderer.write(content, to: &output)
        case .second(let content): renderer.write(content, to: &output)
        }
    }
}

/// Renders an optional node, producing no output when `nil`.
extension OptionalNode: HTMLRenderable {
    /// Emits the wrapped node if present; otherwise writes nothing.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        if let wrapped { renderer.write(wrapped, to: &output) }
    }
}

/// Renders each item produced by a data-driven loop.
extension ForEachNode: HTMLRenderable {
    /// Iterates `data`, applying `content` to each element and emitting the result.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        for element in data {
            renderer.write(content(element), to: &output)
        }
    }
}

/// Renders a runtime array of heterogeneous nodes.
extension ArrayNode: HTMLRenderable {
    /// Emits each child node in order.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        for child in children {
            renderer.write(child, to: &output)
        }
    }
}
