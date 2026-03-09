import Foundation

/// The result of a subprocess execution.
struct ProcessResult: Sendable {
    /// The process exit code.
    let exitCode: Int32

    /// The captured standard output.
    let stdout: String

    /// The captured standard error.
    let stderr: String

    /// Whether the process exited successfully.
    var succeeded: Bool { exitCode == 0 }
}

/// Runs subprocesses and captures their output.
struct ProcessRunner: Sendable {

    /// Runs an executable synchronously and returns the captured output.
    ///
    /// - Parameters:
    ///   - executable: The executable name (resolved via `/usr/bin/env`).
    ///   - arguments: Arguments to pass to the executable.
    ///   - directory: Working directory for the process, or `nil` for current.
    ///   - environment: Additional environment variables to set.
    /// - Throws: An error if the process cannot be launched.
    /// - Returns: A ``ProcessResult`` with exit code and captured output.
    static func run(
        _ executable: String,
        arguments: [String] = [],
        in directory: String? = nil,
        environment: [String: String]? = nil
    ) throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments

        if let directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        if let environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading

        let stdoutBox = LockedValue(Data())
        let stderrBox = LockedValue(Data())

        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            let data = stdoutHandle.readDataToEndOfFile()
            stdoutBox.withLock { $0 = data }
            group.leave()
        }

        group.enter()
        DispatchQueue.global().async {
            let data = stderrHandle.readDataToEndOfFile()
            stderrBox.withLock { $0 = data }
            group.leave()
        }

        group.wait()
        process.waitUntilExit()

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(decoding: stdoutBox.withLock { $0 }, as: UTF8.self),
            stderr: String(decoding: stderrBox.withLock { $0 }, as: UTF8.self)
        )
    }

    /// Runs an executable and streams combined output line-by-line.
    ///
    /// - Parameters:
    ///   - executable: The executable name (resolved via `/usr/bin/env`).
    ///   - arguments: Arguments to pass to the executable.
    ///   - directory: Working directory for the process, or `nil` for current.
    ///   - environment: Additional environment variables to set.
    ///   - onLine: Called for each line of combined stdout/stderr output.
    /// - Throws: An error if the process cannot be launched.
    /// - Returns: The process exit code.
    @discardableResult
    static func stream(
        _ executable: String,
        arguments: [String] = [],
        in directory: String? = nil,
        environment: [String: String]? = nil,
        onLine: @escaping @Sendable (String) -> Void
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments

        if let directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        if let environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                onLine(String(line))
            }
        }

        try process.run()
        process.waitUntilExit()

        outputPipe.fileHandleForReading.readabilityHandler = nil

        return process.terminationStatus
    }

    /// Starts a long-running process and returns the `Process` handle for lifecycle management.
    ///
    /// - Parameters:
    ///   - executable: The executable name (resolved via `/usr/bin/env`).
    ///   - arguments: Arguments to pass to the executable.
    ///   - directory: Working directory for the process, or `nil` for current.
    ///   - environment: Additional environment variables to set.
    /// - Throws: An error if the process cannot be launched.
    /// - Returns: The running `Process` instance.
    static func start(
        _ executable: String,
        arguments: [String] = [],
        in directory: String? = nil,
        environment: [String: String]? = nil
    ) throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        if let directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        if let environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }

        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        return process
    }
}
