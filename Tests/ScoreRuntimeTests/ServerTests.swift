import ScoreCore
import Testing

@testable import ScoreRuntime

private struct TestPage: Page {
    static let path = "/"
    var body: some Node { Heading(.one) { Text { "Home" } } }
}

private struct TestApp: Application {
    var pages: [any Page] { [TestPage()] }
}

@Test func serverConfigurationDefaults() {
    let config = Server.Configuration()
    #expect(config.host == "127.0.0.1")
    #expect(config.port == 8080)
    #expect(config.environment == .development)
}

@Test func serverConfigurationCustom() {
    let config = Server.Configuration(host: "0.0.0.0", port: 3000, environment: .production)
    #expect(config.host == "0.0.0.0")
    #expect(config.port == 3000)
    #expect(config.environment == .production)
}

@Test func serverInitialises() {
    let server = Server(application: TestApp())
    _ = server
}
