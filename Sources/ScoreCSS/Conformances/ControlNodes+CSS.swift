import ScoreCore

extension Button: CSSContainerNode {
    var htmlTag: String? { "button" }
}
extension Form: CSSContainerNode {
    var htmlTag: String? { "form" }
}
extension Input: CSSLeafNode {
    var htmlTag: String? { "input" }
}
extension Label: CSSContainerNode {
    var htmlTag: String? { "label" }
}
extension Select: CSSContainerNode {
    var htmlTag: String? { "select" }
}
extension Option: CSSContainerNode {
    var htmlTag: String? { "option" }
}
extension OptionGroup: CSSContainerNode {
    var htmlTag: String? { "optgroup" }
}
extension TextArea: CSSLeafNode {
    var htmlTag: String? { "textarea" }
}
extension Fieldset: CSSContainerNode {
    var htmlTag: String? { "fieldset" }
}
extension Legend: CSSContainerNode {
    var htmlTag: String? { "legend" }
}
extension Output: CSSContainerNode {
    var htmlTag: String? { "output" }
}
extension DataList: CSSContainerNode {
    var htmlTag: String? { "datalist" }
}
extension Progress: CSSLeafNode {
    var htmlTag: String? { "progress" }
}
extension Meter: CSSLeafNode {
    var htmlTag: String? { "meter" }
}
