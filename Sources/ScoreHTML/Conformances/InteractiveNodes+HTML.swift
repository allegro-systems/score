import ScoreCore

extension Link: HTMLContainerElement {
    var htmlTagName: String { "a" }
    var htmlAttributes: [(String, String)] { [("href", destination)] }
}

extension Dialog: HTMLContainerElement {
    var htmlTagName: String { "dialog" }
    var htmlAttributes: [(String, String)] {
        isOpen ? [("open", "")] : []
    }
}

extension Menu: HTMLContainerElement {
    var htmlTagName: String { "menu" }
}

extension Summary: HTMLContainerElement {
    var htmlTagName: String { "summary" }
}

/// Details requires custom rendering: `<summary>` is placed before body content.
extension Details: HTMLRenderable {
    func renderHTML(into output: inout String, renderer: HTMLRenderer) {
        var a: [(String, String)] = []
        if isOpen { a.append(("open", "")) }
        output.append("<details")
        renderer.writeAttributes(a, to: &output)
        output.append(">")
        renderer.write(summary, to: &output)
        renderer.write(content, to: &output)
        output.append("</details>")
    }
}
