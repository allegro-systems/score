import ScoreCore

extension ReactiveTextNode: HTMLRenderable {
    /// Renders a `<span data-bind="name">text</span>` element.
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        output.append("<span data-bind=\"\(bindingName.attributeEscaped)\">")
        output.append(text.htmlEscaped)
        output.append("</span>")
    }
}
