import Testing

@testable import ScoreCLI

@Test func deployCommandConfiguration() {
    #expect(DeployCommand.configuration.commandName == "deploy")
    #expect(DeployCommand.configuration.abstract == "Deploy to Stage.")
}
