import Testing

@testable import ScoreCLI

@Test func exitCodeValues() {
    #expect(ScoreExitCode.success.rawValue == 0)
    #expect(ScoreExitCode.buildFailure.rawValue == 1)
    #expect(ScoreExitCode.usageError.rawValue == 2)
    #expect(ScoreExitCode.environmentFailure.rawValue == 3)
}

@Test func exitCodeConvertsToArgumentParserExitCode() {
    let exit = ScoreExitCode.success.exitCode
    #expect(exit.rawValue == 0)
}
