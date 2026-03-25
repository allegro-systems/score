import ScoreCore

/// Enables CSS emission for `PresetAnimationModifier`.
///
/// When multiple animation entries are present, they are emitted as a
/// comma-separated CSS `animation` shorthand value.
extension PresetAnimationModifier: CSSRepresentable {
    func cssDeclarations() -> [CSSDeclaration] {
        let values = entries.map { entry -> String in
            formatAnimationEntry(entry)
        }
        return [.init(property: "animation", value: values.joined(separator: ", "))]
    }
}

/// Enables CSS emission for `IntersectionObserverModifier`.
///
/// The element starts hidden (`opacity: 0`) and a `data-scroll-animate`
/// attribute is emitted on the HTML element. The global Score intersection
/// observer script reads this attribute and applies the animation when the
/// element enters the viewport.
///
/// The animation shorthand is stored in a CSS custom property
/// `--score-scroll-animation` so the JS can read and apply it.
extension IntersectionObserverModifier: CSSRepresentable {
    func cssDeclarations() -> [CSSDeclaration] {
        let animationValues = entries.map { formatAnimationEntry($0) }
        let animation = animationValues.joined(separator: ", ")
        return [
            .init(property: "opacity", value: "0"),
            .init(property: "--score-scroll-animation", value: animation),
        ]
    }
}

/// Formats a single animation entry into a CSS animation shorthand value.
private func formatAnimationEntry(_ entry: AnimationEntry) -> String {
    let preset = entry.preset
    let dur = entry.duration ?? preset.defaultDuration
    let tim = entry.timing ?? preset.defaultTiming
    let fill = entry.fillMode ?? preset.defaultFillMode
    let iter = entry.iterationCount ?? preset.defaultIterationCount

    var parts = [preset.keyframesName, CSSEmitter.seconds(dur), tim.rawValue]
    if let delay = entry.delay {
        parts.append(CSSEmitter.seconds(delay))
    }
    if let iter {
        parts.append(iter.cssValue)
    }
    parts.append(fill.rawValue)

    return parts.joined(separator: " ")
}
