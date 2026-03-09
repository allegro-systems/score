import ArgumentParser
import Foundation
import Noora

struct BuildCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the project for production."
    )

    @Flag(name: .long, help: "Output structured JSON errors.")
    var jsonErrors: Bool = false

    mutating func run() async throws {
        do {
            try SwiftToolchain.validate()
        } catch {
            if jsonErrors {
                try emitJSON(
                    StructuredError(
                        code: "toolchain_missing",
                        message: "Swift toolchain not found. Install Swift 6.2 or later.",
                        stage: "build"
                    )
                )
            } else {
                noora.error(
                    .alert("Swift toolchain not found", takeaways: ["Install Swift 6.2 or later from swift.org"])
                )
            }
            throw ExitCode(ScoreExitCode.environmentFailure.rawValue)
        }

        let directory = FileManager.default.currentDirectoryPath
        let resultBox = LockedValue<BuildResult?>(nil)

        do {
            try await noora.collapsibleStep(
                title: "Building project for production",
                successMessage: "Build succeeded",
                errorMessage: "Build failed",
                visibleLines: 5
            ) { addLine in
                let result = try SwiftToolchain.buildStreaming(release: true, in: directory) { line in
                    addLine(TerminalText("\(line)"))
                }
                resultBox.withLock { $0 = result }

                if !result.succeeded {
                    throw CLIError.processFailure(
                        command: "swift build -c release",
                        exitCode: 1,
                        stderr: ""
                    )
                }
            }
        } catch is CLIError {
            if let result = resultBox.withLock({ $0 }) {
                try reportFailure(result)
            }
            throw ExitCode(ScoreExitCode.buildFailure.rawValue)
        }

        if let result = resultBox.withLock({ $0 }), result.succeeded {
            let executable = try SwiftToolchain.findExecutable(in: directory, release: true)

            let emitResult = try ProcessRunner.run(
                executable,
                arguments: ["--build"],
                in: directory
            )

            guard emitResult.succeeded else {
                noora.error(
                    .alert("Static site emission failed", takeaways: ["\(emitResult.stderr.trimmingCharacters(in: .whitespacesAndNewlines))"])
                )
                throw ExitCode(ScoreExitCode.buildFailure.rawValue)
            }

            noora.success(
                .alert(
                    "Production build complete",
                    takeaways: [
                        "Artifacts: .score/"
                    ])
            )
        }
    }

    private func reportFailure(_ result: BuildResult) throws {
        let diagnostics = result.errors.filter { $0.severity == .error }

        if jsonErrors {
            let errors = diagnostics.map { $0.toStructuredError() }
            if errors.isEmpty {
                try emitJSON(
                    StructuredError(code: "compile_error", message: "Build failed", stage: "build")
                )
            } else {
                for error in errors {
                    try emitJSON(error)
                }
            }
        } else {
            if diagnostics.isEmpty {
                noora.error(
                    .alert("Build failed", takeaways: ["Run 'swift build -c release' for full output"])
                )
            } else {
                let takeaways = diagnostics.prefix(10).map {
                    TerminalText("\($0.file):\($0.line):\($0.column) — \($0.message)")
                }
                noora.error(.alert("Build failed with \(diagnostics.count) error(s)", takeaways: takeaways))
            }
        }
    }

    private func emitJSON(_ error: StructuredError) throws {
        print(try error.json())
    }
}
