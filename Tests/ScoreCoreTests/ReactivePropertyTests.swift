import Testing

@testable import ScoreCore

@Test func stateDescriptorStoresFields() {
    let descriptor = StateDescriptor(name: "count", jsInitialValue: "0")
    #expect(descriptor.name == "count")
    #expect(descriptor.jsInitialValue == "0")
    #expect(descriptor.storageKey == "")
    #expect(descriptor.isTheme == false)
}

@Test func stateDescriptorWithStorageKey() {
    let descriptor = StateDescriptor(name: "volume", jsInitialValue: "50", storageKey: "volume")
    #expect(descriptor.storageKey == "volume")
    #expect(descriptor.isTheme == false)
}

@Test func stateDescriptorWithThemeKey() {
    let descriptor = StateDescriptor(name: "isDark", jsInitialValue: "false", storageKey: "as-theme", isTheme: true)
    #expect(descriptor.isTheme == true)
    #expect(descriptor.storageKey == "as-theme")
}

@Test func computedDescriptorStoresFields() {
    let descriptor = ComputedDescriptor(name: "label", body: "count.get() > 0 ? \"Active\" : \"Idle\"")
    #expect(descriptor.name == "label")
    #expect(descriptor.body.contains("count.get()"))
}

@Test func computedDescriptorDefaultsToEmptyBody() {
    let descriptor = ComputedDescriptor(name: "total")
    #expect(descriptor.body == "")
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

@Test func storageKeyThemeConstant() {
    let key = StorageKey.theme
    #expect(key.rawValue == "as-theme")
    #expect(key.isTheme == true)
}

@Test func storageKeyFromStringLiteral() {
    let key: StorageKey = "my-setting"
    #expect(key.rawValue == "my-setting")
    #expect(key.isTheme == false)
}
