import ScoreCore
import Testing

@testable import ScoreCLI

@Test func runEchoCommand() throws {
    let result = try ProcessRunner.run("echo", arguments: ["hello", "world"])

    #expect(result.succeeded)
    #expect(result.exitCode == 0)
    #expect(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "hello world")
    #expect(result.stderr.isEmpty)
}

@Test func runFailingCommand() throws {
    let result = try ProcessRunner.run("false")

    #expect(!result.succeeded)
    #expect(result.exitCode != 0)
}

@Test func runWithDirectory() throws {
    let result = try ProcessRunner.run("pwd", in: "/tmp")

    #expect(result.succeeded)
    let output = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(output.hasSuffix("tmp") || output.hasSuffix("private/tmp"))
}

@Test func runWithEnvironment() throws {
    let result = try ProcessRunner.run(
        "env",
        environment: ["SCORE_TEST_VALUE": "hello_score"]
    )

    #expect(result.succeeded)
    #expect(result.stdout.contains("SCORE_TEST_VALUE=hello_score"))
}

@Test func runCapturesStderr() throws {
    let result = try ProcessRunner.run(
        "bash",
        arguments: ["-c", "echo error_output >&2"]
    )

    #expect(result.stderr.contains("error_output"))
}

@Test func streamCollectsOutput() throws {
    let lines = LockedValue<[String]>([])

    let exitCode = try ProcessRunner.stream(
        "echo",
        arguments: ["line1"]
    ) { line in
        lines.withLock { $0.append(line) }
    }

    #expect(exitCode == 0)
    let collected = lines.withLock { $0 }
    #expect(collected.contains(where: { $0.contains("line1") }))
}

@Test func processResultSucceeded() {
    let success = ProcessResult(exitCode: 0, stdout: "", stderr: "")
    let failure = ProcessResult(exitCode: 1, stdout: "", stderr: "")

    #expect(success.succeeded)
    #expect(!failure.succeeded)
}
