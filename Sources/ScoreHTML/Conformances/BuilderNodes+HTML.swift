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

/// Renders the wrapped content, flattening modifier chains and injecting
/// a CSS scope class when needed.
extension ModifiedNode: HTMLRenderable {
    /// Flattens nested `ModifiedNode` wrappers into a single modifier set,
    /// then renders the innermost content. When the class injector returns
    /// a class name, it is merged directly onto the inner element's tag
    /// if the element conforms to `HTMLAttributeInjectable`; otherwise
    /// the content is wrapped in a `<div>` with that class. When the
    /// injector returns `nil` (CSS nesting handles the styles), the
    /// content renders directly without a wrapper.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        let (allModifiers, innerContent) = flattenedChain()
        let className = renderer.classInjector?(allModifiers)
        let (htmlAttrs, hasEventBindings, hasReactiveBindings) = Self.collectHTMLAttributesAndEvents(from: allModifiers)

        if className != nil || !htmlAttrs.isEmpty || hasEventBindings || hasReactiveBindings {
            var extraAttributes: [(String, String)] = []

            if hasEventBindings {
                let eventIndex = renderer.context.nextEventIndex()
                extraAttributes.append(("data-s", "\(eventIndex)"))
            }

            if hasReactiveBindings {
                let reactiveIndex = renderer.context.nextReactiveIndex()
                extraAttributes.append(("data-r", "\(reactiveIndex)"))
            }

            var classValue = className ?? ""
            if let userClasses = htmlAttrs["class"] {
                if classValue.isEmpty {
                    classValue = userClasses
                } else {
                    classValue += " \(userClasses)"
                }
            }
            if !classValue.isEmpty {
                extraAttributes.append(("class", classValue))
            }
            for (name, value) in htmlAttrs where name != "class" {
                guard name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == ":" }) else { continue }
                extraAttributes.append((name, value))
            }

            if let injectable = innerContent as? HTMLAttributeInjectable {
                injectable.renderHTML(merging: extraAttributes, into: &output, renderer: renderer)
            } else {
                if renderer.isDevMode, let loc = (innerContent as? SourceLocatable)?.sourceLocation {
                    extraAttributes.append(("data-source", "\(loc.fileID):\(loc.line):\(loc.column)"))
                    extraAttributes.append(("data-source-path", "\(loc.filePath):\(loc.line):\(loc.column)"))
                }
                output.append("<div")
                renderer.writeAttributes(extraAttributes, to: &output)
                output.append(">")
                renderer.write(innerContent, to: &output)
                output.append("</div>")
            }
        } else {
            renderer.write(innerContent, to: &output)
        }
    }

    /// Collects HTML attributes and detects event bindings from a flattened
    /// modifier array.
    private static func collectHTMLAttributesAndEvents(
        from modifiers: [any ModifierValue]
    ) -> (attributes: [String: String], hasEventBindings: Bool, hasReactiveBindings: Bool) {
        var result: [String: String] = [:]
        var hasEvents = false
        var hasReactive = false
        for modifier in modifiers {
            if modifier is EventBindingModifier {
                hasEvents = true
            }
            if let visMod = modifier as? ReactiveVisibilityModifier {
                hasReactive = true
                if !visMod.initiallyVisible {
                    result["hidden"] = ""
                }
                continue
            }
            if let a11y = modifier as? AccessibilityModifier {
                if let label = a11y.label {
                    result["aria-label"] = label
                }
                if let isHidden = a11y.isHidden {
                    result["aria-hidden"] = isHidden ? "true" : "false"
                }
                if let role = a11y.role {
                    result["role"] = role
                }
                continue
            }
            guard let attrMod = modifier as? HTMLAttributeModifier else { continue }
            for attr in attrMod.attributes {
                if attr.name == "class", let existing = result["class"] {
                    result["class"] = existing + " " + attr.value
                } else {
                    result[attr.name] = attr.value
                }
            }
        }
        return (result, hasEvents, hasReactive)
    }
}

/// Renders the type-erased wrapped node.
extension Content: HTMLRenderable {
    /// Delegates rendering to the underlying wrapped node.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.write(wrapped, to: &output)
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
