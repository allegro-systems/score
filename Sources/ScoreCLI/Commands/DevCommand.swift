import ArgumentParser
import Foundation
import Noora

struct DevCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "Start the development server with hot reload."
    )

    @Option(name: .long, help: "Port for the dev server.")
    var port: Int = 8080

    @Flag(name: .long, help: "Disable dev tools injection.")
    var noDevtools: Bool = false

    mutating func run() async throws {
        do {
            try SwiftToolchain.validate()
        } catch {
            noora.error(
                .alert("Swift toolchain not found", takeaways: ["Install Swift 6.2 or later from swift.org"])
            )
            throw ExitCode(ScoreExitCode.environmentFailure.rawValue)
        }

        let directory = FileManager.default.currentDirectoryPath
        let runner = DevRunner(
            directory: directory,
            port: port,
            devtools: !noDevtools
        )

        try await runner.start()
    }
}

private nonisolated(unsafe) var _devRunnerServerProcess: LockedValue<Process?>?

private func _devRunnerSignalHandler(_: Int32) {
    _devRunnerServerProcess?.withLock { process in
        if let process, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
    }
    exit(0)
}

/// Manages the development lifecycle: build, run, watch, and rebuild.
final class DevRunner: Sendable {

    let directory: String
    let port: Int
    let devtools: Bool

    private let serverProcess = LockedValue<Process?>(nil)

    init(directory: String, port: Int, devtools: Bool) {
        self.directory = directory
        self.port = port
        self.devtools = devtools
    }

    func start() async throws {
        installSignalHandler()

        let buildSuccess = try await initialBuild()
        guard buildSuccess else {
            throw ExitCode(ScoreExitCode.buildFailure.rawValue)
        }

        let executable: String
        do {
            executable = try SwiftToolchain.findExecutable(in: directory, release: false)
        } catch {
            noora.error(
                .alert(
                    "No executable found",
                    takeaways: [
                        "Ensure your Package.swift contains an .executableTarget"
                    ]
                )
            )
            throw ExitCode(ScoreExitCode.buildFailure.rawValue)
        }

        startServer(executable: executable)

        let watcher = FileWatcher(
            directories: watchDirectories(),
            extensions: ["swift"]
        )

        await watcher.watch { [self] changed in
            let count = changed.count
            let label = count == 1 ? "1 file changed" : "\(count) files changed"
            noora.info(.alert("\(label), rebuilding..."))

            self.stopServer()

            do {
                let result = try SwiftToolchain.build(release: false, in: self.directory)
                if result.success {
                    self.startServer(executable: executable)
                } else {
                    let errors = result.errors.filter { $0.severity == .error }
                    if errors.isEmpty {
                        noora.error(.alert("Rebuild failed", takeaways: ["Check terminal output for details"]))
                    } else {
                        let takeaways = errors.prefix(5).map {
                            TerminalText("\($0.file):\($0.line) — \($0.message)")
                        }
                        noora.error(.alert("Rebuild failed", takeaways: takeaways))
                    }
                }
            } catch {
                noora.error(.alert("Rebuild failed", takeaways: ["\(error)"]))
            }
        }
    }

    private func initialBuild() async throws -> Bool {
        let resultBox = LockedValue<BuildResult?>(nil)

        do {
            try await noora.collapsibleStep(
                title: "Building project",
                successMessage: "Build succeeded",
                errorMessage: "Build failed",
                visibleLines: 5
            ) { addLine in
                let buildResult = try SwiftToolchain.buildStreaming(release: false, in: self.directory) { line in
                    addLine(TerminalText("\(line)"))
                }
                resultBox.withLock { $0 = buildResult }

                if !buildResult.success {
                    throw CLIError.processFailure(command: "swift build", exitCode: 1, stderr: "")
                }
            }
            return true
        } catch is CLIError {
            if let result = resultBox.withLock({ $0 }) {
                let errors = result.errors.filter { $0.severity == .error }
                if !errors.isEmpty {
                    let takeaways = errors.prefix(10).map {
                        TerminalText("\($0.file):\($0.line):\($0.column) — \($0.message)")
                    }
                    noora.error(.alert("Build failed with \(errors.count) error(s)", takeaways: takeaways))
                }
            }
            return false
        }
    }

    private func startServer(executable: String) {
        var env: [String: String] = ["SCORE_ENV": "development"]
        if !devtools {
            env["SCORE_DEVTOOLS"] = "false"
        }

        do {
            let process = try ProcessRunner.start(
                executable,
                arguments: ["--port", "\(port)"],
                in: directory,
                environment: env
            )
            serverProcess.withLock { $0 = process }
        } catch {
            noora.error(.alert("Failed to start server", takeaways: ["\(error)"]))
        }
    }

    private func stopServer() {
        serverProcess.withLock { process in
            guard let process, process.isRunning else { return }
            process.terminate()
            process.waitUntilExit()
        }
        serverProcess.withLock { $0 = nil }
    }

    private func watchDirectories() -> [String] {
        let candidates = ["Sources", "Resources"]
        let fm = FileManager.default
        return
            candidates
            .map { "\(directory)/\($0)" }
            .filter { fm.fileExists(atPath: $0) }
    }

    private func installSignalHandler() {
        _devRunnerServerProcess = serverProcess
        signal(SIGINT, _devRunnerSignalHandler)
    }
}
