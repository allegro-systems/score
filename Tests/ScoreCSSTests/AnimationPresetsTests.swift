import Testing

@testable import ScoreCSS
@testable import ScoreCore

@Suite("AnimationPresets+CSS")
struct AnimationPresetsTests {

    @Test("PresetAnimationModifier emits animation shorthand")
    func presetEmitsAnimation() {
        let modifier = PresetAnimationModifier(preset: .fadeIn)
        let declarations = modifier.cssDeclarations()
        #expect(declarations.count == 1)
        #expect(declarations[0].property == "animation")
        #expect(declarations[0].value.contains("score-fadeIn"))
        #expect(declarations[0].value.contains("ease-out"))
    }

    @Test("Custom duration overrides default")
    func customDuration() {
        let modifier = PresetAnimationModifier(preset: .fadeIn, duration: 1.0)
        let declarations = modifier.cssDeclarations()
        #expect(declarations[0].value.contains("1s"))
    }

    @Test("IntersectionObserverModifier emits opacity 0")
    func observerEmitsHidden() {
        let modifier = IntersectionObserverModifier(preset: .slideUp)
        let declarations = modifier.cssDeclarations()
        #expect(declarations.count == 1)
        #expect(declarations[0].property == "opacity")
        #expect(declarations[0].value == "0")
    }

    @Test("All presets have valid keyframes CSS")
    func allPresetsHaveKeyframes() {
        for preset in AnimationPreset.allCases {
            #expect(!preset.keyframesCSS.isEmpty)
            #expect(!preset.keyframesName.isEmpty)
            #expect(preset.defaultDuration > 0)
        }
    }

    @Test("Spin preset defaults to infinite iteration")
    func spinIsInfinite() {
        let modifier = PresetAnimationModifier(preset: .spin)
        let declarations = modifier.cssDeclarations()
        #expect(declarations[0].value.contains("infinite"))
    }

    @Test("Delay is included when specified")
    func delayIncluded() {
        let modifier = PresetAnimationModifier(preset: .slideUp, delay: 0.5)
        let declarations = modifier.cssDeclarations()
        #expect(declarations[0].value.contains("0.5s"))
    }

    @Test("Multiple animations via array produce comma-separated value")
    func multipleAnimations() {
        // Mirrors the user-facing API: .animate([.fadeIn, .slideUp])
        let modifier = PresetAnimationModifier(entries: [
            AnimationEntry(preset: .fadeIn),
            AnimationEntry(preset: .slideUp),
        ])
        let declarations = modifier.cssDeclarations()
        #expect(declarations.count == 1)
        #expect(declarations[0].property == "animation")
        #expect(declarations[0].value.contains("score-fadeIn"))
        #expect(declarations[0].value.contains("score-slideUp"))
        #expect(declarations[0].value.contains(", "))
    }

    @Test("Multiple animations with individual entry overrides")
    func multipleWithOverrides() {
        // Mirrors: .animate([AnimationEntry(...), AnimationEntry(...)])
        let modifier = PresetAnimationModifier(entries: [
            AnimationEntry(preset: .fadeIn, duration: 0.5),
            AnimationEntry(preset: .slideUp, duration: 0.8, delay: 0.2),
        ])
        let declarations = modifier.cssDeclarations()
        let value = declarations[0].value
        #expect(value.contains("0.5s"))
        #expect(value.contains("0.8s"))
        #expect(value.contains("0.2s"))
    }

    @Test("IntersectionObserver with multiple presets via array")
    func observerMultiplePresets() {
        // Mirrors: .animateOnScroll([.fadeIn, .slideUp])
        let modifier = IntersectionObserverModifier(
            entries: [
                AnimationEntry(preset: .fadeIn),
                AnimationEntry(preset: .slideUp),
            ])
        let declarations = modifier.cssDeclarations()
        #expect(declarations[0].property == "opacity")
    }
}
