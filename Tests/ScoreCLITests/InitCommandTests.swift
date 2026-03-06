import Testing

@testable import ScoreCLI

@Test func initCommandConfiguration() {
    #expect(InitCommand.configuration.commandName == "init")
    #expect(InitCommand.configuration.abstract == "Create a new Score project from a template.")
}

@Test func initCommandParsesProjectName() throws {
    let command = try InitCommand.parse(["MyProject"])
    #expect(command.name == "MyProject")
}

@Test func initCommandParsesTemplateOption() throws {
    let command = try InitCommand.parse(["MyProject", "--template", "blog"])
    #expect(command.name == "MyProject")
    #expect(command.template == "blog")
}

@Test func initCommandTemplateDefaultsToNil() throws {
    let command = try InitCommand.parse(["MyProject"])
    #expect(command.template == nil)
}

@Test func initCommandRequiresProjectName() {
    #expect(throws: Error.self) {
        _ = try InitCommand.parse([])
    }
}
