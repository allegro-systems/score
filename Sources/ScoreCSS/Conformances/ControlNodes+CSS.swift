import ScoreCore

extension Button: CSSContainerNode {
    package var htmlTag: String? { "button" }
}
extension Form: CSSContainerNode {
    package var htmlTag: String? { "form" }
}
extension Input: CSSLeafNode {
    package var htmlTag: String? { "input" }
}
extension Label: CSSContainerNode {
    package var htmlTag: String? { "label" }
}
extension Select: CSSContainerNode {
    package var htmlTag: String? { "select" }
}
extension Option: CSSContainerNode {
    package var htmlTag: String? { "option" }
}
extension OptionGroup: CSSContainerNode {
    package var htmlTag: String? { "optgroup" }
}
extension TextArea: CSSLeafNode {
    package var htmlTag: String? { "textarea" }
}
extension Fieldset: CSSContainerNode {
    package var htmlTag: String? { "fieldset" }
}
extension Legend: CSSContainerNode {
    package var htmlTag: String? { "legend" }
}
extension Output: CSSContainerNode {
    package var htmlTag: String? { "output" }
}
extension DataList: CSSContainerNode {
    package var htmlTag: String? { "datalist" }
}
extension Progress: CSSLeafNode {
    package var htmlTag: String? { "progress" }
}
extension Meter: CSSLeafNode {
    package var htmlTag: String? { "meter" }
}
