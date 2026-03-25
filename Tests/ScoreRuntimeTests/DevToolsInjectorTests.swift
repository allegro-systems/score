import Testing

@testable import ScoreRuntime

@Test func scriptTagInDevelopment() {
    let tag = DevToolsInjector.scriptTag(environment: .development)
    #expect(tag.contains("score-devtools.js"))
    #expect(tag.contains("type=\"module\""))
}

@Test func scriptTagInProductionIsEmpty() {
    let tag = DevToolsInjector.scriptTag(environment: .production)
    #expect(tag.isEmpty)
}

@Test func metadataScriptInDevelopment() {
    let states = [
        JSEmitter.StateInfo(name: "count", initialValue: "0", storageKey: "", isTheme: false),
        JSEmitter.StateInfo(name: "name", initialValue: "\"\"", storageKey: "", isTheme: false),
    ]
    let computeds = [JSEmitter.ComputedInfo(name: "doubled", body: "count.get()*2")]
    let actions = [JSEmitter.ActionInfo(name: "increment", body: "count.set(count.get()+1)")]

    let script = DevToolsInjector.metadataScript(
        pageStates: states,
        pageComputeds: computeds,
        pageActions: actions,
        componentScopes: [],
        environment: .development
    )

    #expect(script.contains("__SCORE_DEV__"))
    #expect(script.contains("\"count\""))
    #expect(script.contains("\"name\""))
    #expect(script.contains("\"doubled\""))
    #expect(script.contains("\"increment\""))
}

@Test func metadataScriptInProductionIsEmpty() {
    let states = [JSEmitter.StateInfo(name: "count", initialValue: "0", storageKey: "", isTheme: false)]

    let script = DevToolsInjector.metadataScript(
        pageStates: states,
        pageComputeds: [],
        pageActions: [],
        componentScopes: [],
        environment: .production
    )
    #expect(script.isEmpty)
}

@Test func metadataScriptEmptyContentOmitsPageData() {
    let script = DevToolsInjector.metadataScript(
        pageStates: [],
        pageComputeds: [],
        pageActions: [],
        componentScopes: [],
        environment: .development
    )
    #expect(script.contains("__SCORE_DEV__"))
    #expect(!script.contains("page:"))
    #expect(!script.contains("elements:"))
}

@Test func metadataScriptIncludesComponentScopes() {
    var scope = JSEmitter.ComponentScope()
    scope.name = "ThemeToggle"
    scope.states = [JSEmitter.StateInfo(name: "isDark", initialValue: "false", storageKey: "as-theme", isTheme: true)]
    scope.actions = [JSEmitter.ActionInfo(name: "toggle", body: "isDark.set(!isDark.get())")]

    let script = DevToolsInjector.metadataScript(
        pageStates: [],
        pageComputeds: [],
        pageActions: [],
        componentScopes: [scope],
        environment: .development
    )

    #expect(script.contains("ThemeToggle"))
    #expect(script.contains("isDark"))
    #expect(script.contains("toggle"))
}

@Test func clientScriptIsNonEmpty() {
    #expect(!DevToolsInjector.clientScript.isEmpty)
    #expect(DevToolsInjector.clientScript.contains("score-devtools-root"))
}
