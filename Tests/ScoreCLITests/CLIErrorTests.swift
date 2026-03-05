import Testing

@testable import ScoreCLI

@Test func unknownTemplateErrorDescription() {
    let error = CLIError.unknownTemplate("foo")
    #expect(error.description.contains("foo"))
    #expect(error.description.contains("Unknown template"))
}

@Test func directoryExistsErrorDescription() {
    let error = CLIError.directoryExists("/tmp/MyApp")
    #expect(error.description.contains("/tmp/MyApp"))
}

@Test func processFailureErrorDescription() {
    let error = CLIError.processFailure(command: "swift build", exitCode: 1, stderr: "compile error")
    #expect(error.description.contains("swift build"))
    #expect(error.description.contains("compile error"))
}

@Test func toolchainNotFoundErrorDescription() {
    let error = CLIError.toolchainNotFound
    #expect(error.description.contains("Swift toolchain"))
}

@Test func networkErrorDescription() {
    let error = CLIError.networkError("timeout")
    #expect(error.description.contains("timeout"))
}

@Test func fileSystemErrorDescription() {
    let error = CLIError.fileSystemError("permission denied")
    #expect(error.description.contains("permission denied"))
}
