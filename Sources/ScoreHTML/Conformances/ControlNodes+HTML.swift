import ScoreCore

extension Button: HTMLContainerElement {
    package var htmlTagName: String { "button" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("type", type.rawValue)]
        if let v = form { a.append(("form", v)) }
        if let v = name { a.append(("name", v)) }
        if let v = value { a.append(("value", v)) }
        if isDisabled { a.append(("disabled", "")) }
        return a
    }
}

extension Form: HTMLContainerElement {
    package var htmlTagName: String { "form" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if actionRefName == nil {
            a.append(("action", action))
            a.append(("method", method.rawValue))
            if let v = encoding { a.append(("enctype", v.rawValue)) }
        }
        if let v = id { a.append(("id", v)) }
        return a
    }
}

extension Input: HTMLVoidElement {
    package var htmlTagName: String { "input" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("type", type.rawValue)]
        if let v = name { a.append(("name", v)) }
        if let v = placeholder { a.append(("placeholder", v)) }
        if let v = value { a.append(("value", v)) }
        if let v = id { a.append(("id", v)) }
        if let v = reactiveBindingName { a.append(("data-bind-value", v)) }
        if isRequired { a.append(("required", "")) }
        if isDisabled { a.append(("disabled", "")) }
        if isReadOnly { a.append(("readonly", "")) }
        if isChecked { a.append(("checked", "")) }
        if let v = min { a.append(("min", v)) }
        if let v = max { a.append(("max", v)) }
        if let v = list { a.append(("list", v)) }
        return a
    }
}

extension Label: HTMLContainerElement {
    package var htmlTagName: String { "label" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = forID { a.append(("for", v)) }
        return a
    }
}

extension Select: HTMLContainerElement {
    package var htmlTagName: String { "select" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = name { a.append(("name", v)) }
        if let v = id { a.append(("id", v)) }
        if isRequired { a.append(("required", "")) }
        if isDisabled { a.append(("disabled", "")) }
        if isMultiple { a.append(("multiple", "")) }
        return a
    }
}

extension Option: HTMLContainerElement {
    package var htmlTagName: String { "option" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = value { a.append(("value", v)) }
        if isSelected { a.append(("selected", "")) }
        if isDisabled { a.append(("disabled", "")) }
        return a
    }
}

extension OptionGroup: HTMLContainerElement {
    package var htmlTagName: String { "optgroup" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = [("label", label)]
        if isDisabled { a.append(("disabled", "")) }
        return a
    }
}

/// TextArea requires custom rendering: inner text is not a child Node.
extension TextArea: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = name { a.append(("name", v)) }
        if let v = placeholder { a.append(("placeholder", v)) }
        if let v = rows { a.append(("rows", String(v))) }
        if let v = columns { a.append(("cols", String(v))) }
        if let v = id { a.append(("id", v)) }
        if let v = reactiveBindingName { a.append(("data-bind-value", v)) }
        if isRequired { a.append(("required", "")) }
        if isDisabled { a.append(("disabled", "")) }
        if isReadOnly { a.append(("readonly", "")) }
        output.append("<textarea")
        renderer.writeAttributes(a, to: &output)
        output.append(">")
        if let value { output.append(value.htmlEscaped) }
        output.append("</textarea>")
    }
}

extension Fieldset: HTMLContainerElement {
    package var htmlTagName: String { "fieldset" }
    package var htmlAttributes: [(String, String)] {
        isDisabled ? [("disabled", "")] : []
    }
}

extension Legend: HTMLContainerElement {
    package var htmlTagName: String { "legend" }
}

extension Output: HTMLContainerElement {
    package var htmlTagName: String { "output" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = forID { a.append(("for", v)) }
        return a
    }
}

extension DataList: HTMLContainerElement {
    package var htmlTagName: String { "datalist" }
    package var htmlAttributes: [(String, String)] {
        var a: [(String, String)] = []
        if let v = id { a.append(("id", v)) }
        return a
    }
}

/// Progress requires custom rendering: no child content node.
extension Progress: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = value { a.append(("value", v.cleanValue)) }
        if let v = max { a.append(("max", v.cleanValue)) }
        output.append("<progress")
        renderer.writeAttributes(a, to: &output)
        output.append("></progress>")
    }
}

/// Meter requires custom rendering: no child content node.
extension Meter: HTMLRenderable {
    package func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("value", value.cleanValue)]
        if let v = min { a.append(("min", v.cleanValue)) }
        if let v = max { a.append(("max", v.cleanValue)) }
        if let v = low { a.append(("low", v.cleanValue)) }
        if let v = high { a.append(("high", v.cleanValue)) }
        if let v = optimum { a.append(("optimum", v.cleanValue)) }
        output.append("<meter")
        renderer.writeAttributes(a, to: &output)
        output.append("></meter>")
    }
}
