import Testing

@testable import ScoreRuntime

@Test func annotateComponentInDevelopment() {
    let html = "<div>Hello</div>"
    let result = DevToolsInjector.annotateComponent(
        bodyHTML: html,
        componentName: "HomePage",
        sourceFile: "Sources/App/HomePage.swift",
        sourceLine: 12,
        environment: .development
    )

    #expect(result.contains("data-score-component=\"HomePage\""))
    #expect(result.contains("data-score-file=\"Sources/App/HomePage.swift\""))
    #expect(result.contains("data-score-line=\"12\""))
}

@Test func annotateComponentInProductionIsNoOp() {
    let html = "<div>Hello</div>"
    let result = DevToolsInjector.annotateComponent(
        bodyHTML: html,
        componentName: "HomePage",
        sourceFile: "Sources/App/HomePage.swift",
        sourceLine: 12,
        environment: .production
    )

    #expect(result == html)
    #expect(!result.contains("data-score-component"))
}

@Test func annotateComponentPreservesExistingAttributes() {
    let html = "<div class=\"main\">Content</div>"
    let result = DevToolsInjector.annotateComponent(
        bodyHTML: html,
        componentName: "TestPage",
        sourceFile: "test.swift",
        sourceLine: 1,
        environment: .development
    )

    #expect(result.contains("class=\"main\""))
    #expect(result.contains("data-score-component=\"TestPage\""))
}

@Test func scriptTagInDevelopment() {
    let tag = DevToolsInjector.scriptTag(environment: .development)
    #expect(tag.contains("score-devtools.js"))
    #expect(tag.contains("type=\"module\""))
}

@Test func scriptTagInProductionIsEmpty() {
    let tag = DevToolsInjector.scriptTag(environment: .production)
    #expect(tag.isEmpty)
}

@Test func stateMetadataScriptInDevelopment() {
    let script = DevToolsInjector.stateMetadataScript(
        stateNames: ["count", "name"],
        computedNames: ["doubled"],
        environment: .development
    )

    #expect(script.contains("__SCORE_DEV_META__"))
    #expect(script.contains("\"count\""))
    #expect(script.contains("\"name\""))
    #expect(script.contains("\"doubled\""))
}

@Test func stateMetadataScriptInProductionIsEmpty() {
    let script = DevToolsInjector.stateMetadataScript(
        stateNames: ["count"],
        computedNames: [],
        environment: .production
    )
    #expect(script.isEmpty)
}

@Test func stateMetadataScriptEmptyNamesIsEmpty() {
    let script = DevToolsInjector.stateMetadataScript(
        stateNames: [],
        computedNames: [],
        environment: .development
    )
    #expect(script.isEmpty)
}
