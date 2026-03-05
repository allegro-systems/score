import ArgumentParser

/// Stable exit codes per the Score CLI contract.
///
/// - `success` (0): Command completed without error.
/// - `buildFailure` (1): Compile, build, or deploy failure.
/// - `usageError` (2): Invalid arguments or usage.
/// - `environmentFailure` (3): Missing toolchain or prerequisite.
enum ScoreExitCode: Int32 {
    case success = 0
    case buildFailure = 1
    case usageError = 2
    case environmentFailure = 3

    var exitCode: ExitCode { ExitCode(rawValue) }
}
