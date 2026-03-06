import ScoreCore

// MARK: - Layout Nodes

extension Stack: _JSWalkable {}
extension Main: _JSWalkable {}
extension Section: _JSWalkable {}
extension Article: _JSWalkable {}
extension Header: _JSWalkable {}
extension Footer: _JSWalkable {}
extension Aside: _JSWalkable {}
extension Navigation: _JSWalkable {}
extension Group: _JSWalkable {}

// MARK: - Content Nodes

extension Heading: _JSWalkable {}
extension Paragraph: _JSWalkable {}
extension Text: _JSWalkable {}
extension Strong: _JSWalkable {}
extension Emphasis: _JSWalkable {}
extension Small: _JSWalkable {}
extension Mark: _JSWalkable {}
extension Code: _JSWalkable {}
extension Preformatted: _JSWalkable {}
extension Blockquote: _JSWalkable {}
extension Address: _JSWalkable {}

/// Leaf node — `<hr>` has no children.
extension HorizontalRule: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

/// Leaf node — `<br>` has no children.
extension LineBreak: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

// MARK: - Control Nodes

extension Button: _JSWalkable {}
extension Form: _JSWalkable {}

/// Leaf node — `<input>` is a void element.
extension Input: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension Label: _JSWalkable {}
extension Select: _JSWalkable {}
extension Option: _JSWalkable {}
extension OptionGroup: _JSWalkable {}

/// Leaf node — `<textarea>` holds a string value, not child nodes.
extension TextArea: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension Fieldset: _JSWalkable {}
extension Legend: _JSWalkable {}
extension Output: _JSWalkable {}
extension DataList: _JSWalkable {}

/// Leaf node — `<progress>` carries numeric attributes only.
extension Progress: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

/// Leaf node — `<meter>` carries numeric attributes only.
extension Meter: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

// MARK: - Interactive Nodes

extension Link: _JSWalkable {}
extension Dialog: _JSWalkable {}
extension Menu: _JSWalkable {}
extension Summary: _JSWalkable {}
extension Details: _JSWalkable {}

// MARK: - Media Nodes

/// Leaf node — `<img>` is a void element.
extension Image: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension Figure: _JSWalkable {}
extension FigureCaption: _JSWalkable {}

/// Leaf node — `<source>` is a void element.
extension Source: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

/// Leaf node — `<track>` is a void element.
extension Track: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}

extension Audio: _JSWalkable {}
extension Video: _JSWalkable {}
extension Picture: _JSWalkable {}
extension Canvas: _JSWalkable {}

// MARK: - List Nodes

extension UnorderedList: _JSWalkable {}
extension OrderedList: _JSWalkable {}
extension ListItem: _JSWalkable {}
extension DescriptionList: _JSWalkable {}
extension DescriptionTerm: _JSWalkable {}
extension DescriptionDetails: _JSWalkable {}

// MARK: - Table Nodes

extension Table: _JSWalkable {}
extension TableCaption: _JSWalkable {}
extension TableHead: _JSWalkable {}
extension TableBody: _JSWalkable {}
extension TableFooter: _JSWalkable {}
extension TableRow: _JSWalkable {}
extension TableHeaderCell: _JSWalkable {}
extension TableCell: _JSWalkable {}
extension TableColumnGroup: _JSWalkable {}

/// Leaf node — `<col>` is a void element.
extension TableColumn: _JSWalkable {
    func walkChildrenForJS(bindings: inout [JSEmitter.EventBinding], index: inout Int) {}
    func walkChildrenForScopes(scopes: inout [JSEmitter.ComponentScope]) {}
}
