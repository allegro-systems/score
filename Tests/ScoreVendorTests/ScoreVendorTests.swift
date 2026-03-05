import Testing

@testable import ScoreVendor

@Test func scriptStoresSourceURL() {
    let script = Script(src: "https://example.com/app.js")
    #expect(script.src == "https://example.com/app.js")
    #expect(script.isAsync == false)
    #expect(script.isDeferred == false)
    #expect(script.attributes.isEmpty)
}

@Test func scriptStoresAsyncFlag() {
    let script = Script(src: "https://example.com/app.js", async: true)
    #expect(script.isAsync == true)
    #expect(script.isDeferred == false)
}

@Test func scriptStoresDeferFlag() {
    let script = Script(src: "https://example.com/app.js", defer: true)
    #expect(script.isDeferred == true)
    #expect(script.isAsync == false)
}

@Test func scriptStoresCustomAttributes() {
    let script = Script(
        src: "https://example.com/app.js",
        attributes: ["data-site": "abc", "crossorigin": "anonymous"]
    )
    #expect(script.attributes["data-site"] == "abc")
    #expect(script.attributes["crossorigin"] == "anonymous")
}

@Test func googleAnalyticsProviderHasCorrectScript() {
    let provider = AnalyticsProvider.googleAnalytics(measurementID: "G-TEST123")
    #expect(provider.name == "Google Analytics")
    #expect(provider.scripts.count == 1)
    #expect(provider.scripts[0].src.contains("G-TEST123"))
    #expect(provider.scripts[0].isAsync == true)
}

@Test func plausibleProviderHasCorrectScript() {
    let provider = AnalyticsProvider.plausible(domain: "example.com")
    #expect(provider.name == "Plausible")
    #expect(provider.scripts.count == 1)
    #expect(provider.scripts[0].src == "https://plausible.io/js/script.js")
    #expect(provider.scripts[0].isDeferred == true)
    #expect(provider.scripts[0].attributes["data-domain"] == "example.com")
}

@Test func customProviderUsesGivenValues() {
    let provider = AnalyticsProvider.custom(
        name: "Fathom",
        src: "https://cdn.fathom.com/script.js",
        attributes: ["data-site": "SITE123"]
    )
    #expect(provider.name == "Fathom")
    #expect(provider.scripts.count == 1)
    #expect(provider.scripts[0].src == "https://cdn.fathom.com/script.js")
    #expect(provider.scripts[0].attributes["data-site"] == "SITE123")
}

@Test func vendorIntegrationProtocolConformance() {
    struct TestIntegration: VendorIntegration {
        var scripts: [Script] {
            [
                Script(src: "https://example.com/widget.js", async: true),
                Script(src: "https://example.com/helpers.js", defer: true),
            ]
        }
    }

    let integration = TestIntegration()
    #expect(integration.scripts.count == 2)
    #expect(integration.scripts[0].isAsync == true)
    #expect(integration.scripts[1].isDeferred == true)
}

@Test func analyticsProviderConformsToSendable() {
    let provider = AnalyticsProvider.plausible(domain: "example.com")
    let sendable: any Sendable = provider
    #expect(sendable is AnalyticsProvider)
}
