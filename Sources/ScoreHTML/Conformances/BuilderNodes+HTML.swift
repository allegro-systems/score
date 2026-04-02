import ScoreCore

/// Produces no HTML output.
extension EmptyNode: HTMLRenderable {
    /// Emits nothing.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {}
}

/// Renders escaped text content directly into the output stream.
extension TextNode: HTMLRenderable {
    /// Appends the text content with `<`, `>`, `&`, and `"` escaped.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        output.append(content.htmlEscaped)
    }
}

/// Renders raw content directly into the output stream without escaping.
extension RawTextNode: HTMLRenderable {
    /// Appends the raw content verbatim with no HTML escaping.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
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
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        let (allModifiers, innerContent) = flattenedChain()
        let className = renderer.classInjector?(allModifiers, renderer.context.currentComponentScope)
        let (htmlAttrs, hasEventBindings, hasReactiveBindings, eventAction) = Self.collectHTMLAttributesAndEvents(from: allModifiers)

        if className != nil || !htmlAttrs.isEmpty || hasEventBindings || hasReactiveBindings {
            var extraAttributes: [(String, String)] = []

            if hasEventBindings {
                if let action = eventAction {
                    let scope = renderer.context.currentComponentScope ?? "page"
                    extraAttributes.append(("data-action", "\(scope):\(action)"))
                } else {
                    let eventIndex = renderer.context.nextEventIndex()
                    extraAttributes.append(("data-s", "\(eventIndex)"))
                }
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

            if renderer.isDevMode {
                let styleModifiers = allModifiers.filter {
                    !($0 is EventBindingModifier) && !($0 is ReactiveVisibilityModifier)
                        && !($0 is HTMLAttributeModifier) && !($0 is AccessibilityModifier)
                }
                if !styleModifiers.isEmpty {
                    let descriptions = styleModifiers.map { $0.devDescription }
                    let escaped = descriptions.joined(separator: ";;")
                        .replacingOccurrences(of: "\"", with: "&quot;")
                    extraAttributes.append(("data-score-modifiers", escaped))
                }
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
    ) -> (attributes: [String: String], hasEventBindings: Bool, hasReactiveBindings: Bool, eventAction: String?) {
        var result: [String: String] = [:]
        var hasEvents = false
        var hasReactive = false
        var eventAction: String?
        for modifier in modifiers {
            if let binding = modifier as? EventBindingModifier {
                hasEvents = true
                if eventAction == nil {
                    eventAction = binding.handler
                }
            }
            if let visMod = modifier as? ReactiveVisibilityModifier {
                hasReactive = true
                if !visMod.initiallyVisible {
                    result["class"] = (result["class"].map { $0 + " " } ?? "") + "score-hidden"
                    result["aria-hidden"] = "true"
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
            if let scrollMod = modifier as? IntersectionObserverModifier {
                var config: [String] = []
                config.append("t:\(scrollMod.threshold)")
                if scrollMod.rootMargin != "0px" {
                    config.append("m:\(scrollMod.rootMargin)")
                }
                if !scrollMod.once {
                    config.append("once:0")
                }
                result["data-scroll-animate"] = config.joined(separator: ";")
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
        return (result, hasEvents, hasReactive, eventAction)
    }
}

/// Renders the type-erased wrapped node.
extension Content: HTMLRenderable {
    /// Delegates rendering to the underlying wrapped node.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.write(wrapped, to: &output)
    }
}

/// Renders all children in declaration order via parameter pack expansion.
extension TupleNode: HTMLRenderable {
    /// Emits each child using `repeat each children`.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        repeat renderer.write(each children, to: &output)
    }
}

/// Renders the active branch of an `if`/`else` builder expression.
extension ConditionalNode: HTMLRenderable {
    /// Emits the `.first` or `.second` branch depending on which was chosen at build time.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        switch storage {
        case .first(let content): renderer.write(content, to: &output)
        case .second(let content): renderer.write(content, to: &output)
        }
    }
}

/// Renders an optional node, producing no output when `nil`.
extension OptionalNode: HTMLRenderable {
    /// Emits the wrapped node if present; otherwise writes nothing.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        if let wrapped { renderer.write(wrapped, to: &output) }
    }
}

/// Renders each item produced by a data-driven loop.
extension ForEachNode: HTMLRenderable {
    /// Iterates `data`, applying `content` to each element and emitting the result.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        for element in data {
            renderer.write(content(element), to: &output)
        }
    }
}

/// Renders a runtime array of heterogeneous nodes.
extension ArrayNode: HTMLRenderable {
    /// Emits each child node in order.
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        for child in children {
            renderer.write(child, to: &output)
        }
    }
}
