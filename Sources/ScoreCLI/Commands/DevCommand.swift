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
    let pid = _devRunnerServerProcess?.withLock { $0?.processIdentifier } ?? 0
    if pid > 0 {
        // Send SIGTERM for graceful NIO shutdown.
        kill(pid, SIGTERM)
        // Wait briefly, then force-kill if still alive.
        usleep(500_000)
        // Check if process is still running (waitpid with WNOHANG).
        var status: Int32 = 0
        if waitpid(pid, &status, WNOHANG) == 0 {
            kill(pid, SIGKILL)
            waitpid(pid, &status, 0)
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
        printStatusBlock(icon: "✔", style: .success, message: "Server running on \(serverURL)")

        let watcher = FileWatcher(
            directories: watchDirectories(),
            extensions: ["swift"]
        )

        await watcher.watch { [self] changed in
            let count = changed.count
            let label = count == 1 ? "1 file changed" : "\(count) files changed"
            self.replaceStatusBlock(icon: "i", style: .info, message: "\(label), rebuilding...")

            self.stopServer()

            do {
                let result = try SwiftToolchain.build(release: false, in: self.directory)
                if result.succeeded {
                    self.startServer(executable: executable)
                    self.replaceStatusBlock(icon: "✔", style: .success, message: "Server running on \(self.serverURL)")
                } else {
                    let errors = result.errors.filter { $0.severity == .error }
                    if errors.isEmpty {
                        self.replaceStatusBlock(icon: "⨯", style: .error, message: "Rebuild failed — check terminal output for details")
                    } else {
                        let detail = errors.prefix(3).map { "\($0.file):\($0.line) — \($0.message)" }.joined(separator: "\n")
                        self.replaceStatusBlock(icon: "⨯", style: .error, message: "Rebuild failed\n\(detail)")
                    }
                }
            } catch {
                self.replaceStatusBlock(icon: "⨯", style: .error, message: "Rebuild failed — \(error)")
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

                if !buildResult.succeeded {
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

    private var serverURL: String {
        "http://127.0.0.1:\(port)"
    }

    private let statusLineCount = LockedValue<Int>(0)

    enum StatusStyle {
        case info, success, error
    }

    private func printStatusBlock(icon: String, style: StatusStyle, message: String) {
        let styledIcon: String
        switch style {
        case .info: styledIcon = "\u{1B}[36m\(icon)\u{1B}[0m"
        case .success: styledIcon = "\u{1B}[32m\(icon)\u{1B}[0m"
        case .error: styledIcon = "\u{1B}[31m\(icon)\u{1B}[0m"
        }
        let output = "  \(styledIcon) \(message)"
        print(output)
        let lineCount = output.components(separatedBy: "\n").count
        statusLineCount.withLock { $0 = lineCount }
    }

    private func replaceStatusBlock(icon: String, style: StatusStyle, message: String) {
        let previousCount = statusLineCount.withLock { $0 }
        if previousCount > 0 {
            let moveUp = String(repeating: "\u{1B}[1A\u{1B}[2K", count: previousCount)
            print(moveUp, terminator: "\r")
        }
        printStatusBlock(icon: icon, style: style, message: message)
    }

    private func installSignalHandler() {
        _devRunnerServerProcess = serverProcess
        signal(SIGINT, _devRunnerSignalHandler)
    }
}
