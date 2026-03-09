import Testing

@testable import ScoreCore

@Test func stateReturnsInitialValue() {
    @State var count = 0
    #expect(count == 0)
}

@Test func stateAcceptsStringValue() {
    @State var name = "hello"
    #expect(name == "hello")
}

@Test func stateSupportsMutation() {
    @State var value = 10
    value = 42
    #expect(value == 42)
}

@Test func computedEvaluatesClosure() {
    @Computed var doubled = 5 * 2
    #expect(doubled == 10)
}

@Test func computedProducesCorrectValue() {
    let compute = Computed<Int>(wrappedValue: 42)
    #expect(compute.wrappedValue == 42)
}

@Test func actionDescriptorCreatesSuccessfully() {
    let descriptor = ActionDescriptor(name: "toggle")
    #expect(descriptor.name == "toggle")
}

@Test func domEventStoresName() {
    let event = DOMEvent("click")
    #expect(event.name == "click")
}

@Test func domEventStaticCasesAreCorrect() {
    #expect(DOMEvent.click.name == "click")
    #expect(DOMEvent.input.name == "input")
    #expect(DOMEvent.change.name == "change")
    #expect(DOMEvent.submit.name == "submit")
    #expect(DOMEvent.keydown.name == "keydown")
    #expect(DOMEvent.keyup.name == "keyup")
    #expect(DOMEvent.focus.name == "focus")
    #expect(DOMEvent.blur.name == "blur")
}

@Test func domEventIsHashable() {
    let set: Set<DOMEvent> = [.click, .input, .click]
    #expect(set.count == 2)
}

@Test func eventBindingModifierStoresFields() {
    let binding = EventBindingModifier(event: .click, handler: "handleClick")
    #expect(binding.event == .click)
    #expect(binding.handler == "handleClick")
}

@Test func nodeOnExtensionCreatesModifiedNode() {
    let node = TextNode("Click me").on(.click, action: "doSomething")
    #expect(node.modifiers.count == 1)

    let binding = node.modifiers[0] as? EventBindingModifier
    #expect(binding?.event == .click)
    #expect(binding?.handler == "doSomething")
}

@Test func multipleEventBindingsAccumulate() {
    let node = TextNode("Input")
        .on(.focus, action: "handleFocus")
        .on(.blur, action: "handleBlur")
    #expect(node.modifiers.count == 1)

    let outer = node.modifiers[0] as? EventBindingModifier
    #expect(outer?.event == .blur)

    let inner = node.content.modifiers[0] as? EventBindingModifier
    #expect(inner?.event == .focus)
}
