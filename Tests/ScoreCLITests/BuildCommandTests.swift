import Testing

@testable import ScoreCLI

@Test func buildCommandConfiguration() {
    #expect(BuildCommand.configuration.commandName == "build")
    #expect(BuildCommand.configuration.abstract == "Build the project for production.")
}

@Test func buildCommandParsesDefaultFlags() throws {
    let command = try BuildCommand.parse([])
    #expect(command.jsonErrors == false)
}

@Test func buildCommandParsesJSONErrorsFlag() throws {
    let command = try BuildCommand.parse(["--json-errors"])
    #expect(command.jsonErrors == true)
}
