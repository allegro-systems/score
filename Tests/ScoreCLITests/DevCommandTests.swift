import Testing

@testable import ScoreCLI

@Test func devCommandConfiguration() {
    #expect(DevCommand.configuration.commandName == "dev")
    #expect(DevCommand.configuration.abstract == "Start the development server with hot reload.")
}

@Test func devCommandParsesDefaultPort() throws {
    let command = try DevCommand.parse([])
    #expect(command.port == 8080)
}

@Test func devCommandParsesCustomPort() throws {
    let command = try DevCommand.parse(["--port", "3000"])
    #expect(command.port == 3000)
}

@Test func devCommandParsesNoDevtoolsFlag() throws {
    let command = try DevCommand.parse(["--no-devtools"])
    #expect(command.noDevtools == true)
}

@Test func devCommandDefaultNoDevtoolsIsFalse() throws {
    let command = try DevCommand.parse([])
    #expect(command.noDevtools == false)
}
