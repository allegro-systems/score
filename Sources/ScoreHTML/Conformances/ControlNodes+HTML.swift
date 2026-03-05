import ScoreCore

/// Renders as a `<button>` element with type, form association, and state attributes.
extension Button: HTMLRenderable {
    /// Emits a `<button>` with `type`, and optional `form`, `name`, `value`, and `disabled`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("type", type.rawValue)]
        if let v = form { a.append(("form", v)) }
        if let v = name { a.append(("name", v)) }
        if let v = value { a.append(("value", v)) }
        if isDisabled { a.append(("disabled", "")) }
        renderer.tag("button", a, content: content, to: &output)
    }
}

/// Renders as a `<form>` element with submission attributes.
extension Form: HTMLRenderable {
    /// Emits a `<form>` with `action`, `method`, optional `enctype`, and optional `id`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("action", action), ("method", method.rawValue)]
        if let v = encoding { a.append(("enctype", v.rawValue)) }
        if let v = id { a.append(("id", v)) }
        renderer.tag("form", a, content: content, to: &output)
    }
}

/// Renders as the `<input>` void element with type, name, and state attributes.
extension Input: HTMLRenderable {
    /// Emits a self-closing `<input>` with `type` and optional `name`, `placeholder`, `value`, `id`, `required`, `disabled`, and `readonly`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("type", type.rawValue)]
        if let v = name { a.append(("name", v)) }
        if let v = placeholder { a.append(("placeholder", v)) }
        if let v = value { a.append(("value", v)) }
        if let v = id { a.append(("id", v)) }
        if isRequired { a.append(("required", "")) }
        if isDisabled { a.append(("disabled", "")) }
        if isReadOnly { a.append(("readonly", "")) }
        if isChecked { a.append(("checked", "")) }
        if let v = min { a.append(("min", v)) }
        if let v = max { a.append(("max", v)) }
        if let v = list { a.append(("list", v)) }
        renderer.voidTag("input", a, to: &output)
    }
}

/// Renders as a `<label>` element, optionally associated with a control via `for`.
extension Label: HTMLRenderable {
    /// Emits a `<label>` with an optional `for` attribute linking it to a labelled control.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = forID { a.append(("for", v)) }
        renderer.tag("label", a, content: content, to: &output)
    }
}

/// Renders as a `<select>` dropdown element.
extension Select: HTMLRenderable {
    /// Emits a `<select>` with optional `name`, `id`, `required`, `disabled`, and `multiple`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = name { a.append(("name", v)) }
        if let v = id { a.append(("id", v)) }
        if isRequired { a.append(("required", "")) }
        if isDisabled { a.append(("disabled", "")) }
        if isMultiple { a.append(("multiple", "")) }
        renderer.tag("select", a, content: content, to: &output)
    }
}

/// Renders as an `<option>` element within a `<select>` or `<datalist>`.
extension Option: HTMLRenderable {
    /// Emits an `<option>` with optional `value`, `selected`, and `disabled`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = value { a.append(("value", v)) }
        if isSelected { a.append(("selected", "")) }
        if isDisabled { a.append(("disabled", "")) }
        renderer.tag("option", a, content: content, to: &output)
    }
}

/// Renders as an `<optgroup>` labelled group of options.
extension OptionGroup: HTMLRenderable {
    /// Emits an `<optgroup>` with a `label` and optional `disabled`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = [("label", label)]
        if isDisabled { a.append(("disabled", "")) }
        renderer.tag("optgroup", a, content: content, to: &output)
    }
}

/// Renders as a `<textarea>` multi-line text input.
extension TextArea: HTMLRenderable {
    /// Emits a `<textarea>` with optional `name`, `placeholder`, `rows`, `cols`, `id`, `required`, `disabled`, `readonly`, and pre-filled value.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = name { a.append(("name", v)) }
        if let v = placeholder { a.append(("placeholder", v)) }
        if let v = rows { a.append(("rows", String(v))) }
        if let v = columns { a.append(("cols", String(v))) }
        if let v = id { a.append(("id", v)) }
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

/// Renders as a `<fieldset>` form grouping element.
extension Fieldset: HTMLRenderable {
    /// Emits a `<fieldset>` with optional `disabled`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if isDisabled { a.append(("disabled", "")) }
        renderer.tag("fieldset", a, content: content, to: &output)
    }
}

/// Renders as a `<legend>` caption for a `<fieldset>`.
extension Legend: HTMLRenderable {
    /// Wraps content in a `<legend>` element.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        renderer.tag("legend", content: content, to: &output)
    }
}

/// Renders as an `<output>` calculated result element.
extension Output: HTMLRenderable {
    /// Emits an `<output>` with an optional `for` attribute referencing input controls.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = forID { a.append(("for", v)) }
        renderer.tag("output", a, content: content, to: &output)
    }
}

/// Renders as a `<datalist>` predefined options element.
extension DataList: HTMLRenderable {
    /// Emits a `<datalist>` with an optional `id` for linking to an `<input>`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = id { a.append(("id", v)) }
        renderer.tag("datalist", a, content: content, to: &output)
    }
}

/// Renders as a `<progress>` task completion indicator.
extension Progress: HTMLRenderable {
    /// Emits a `<progress>` with optional `value` and `max` attributes.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if let v = value { a.append(("value", v.cleanValue)) }
        if let v = max { a.append(("max", v.cleanValue)) }
        output.append("<progress")
        renderer.writeAttributes(a, to: &output)
        output.append("></progress>")
    }
}

/// Renders as a `<meter>` scalar measurement element.
extension Meter: HTMLRenderable {
    /// Emits a `<meter>` with `value` and optional `min`, `max`, `low`, `high`, and `optimum`.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
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
