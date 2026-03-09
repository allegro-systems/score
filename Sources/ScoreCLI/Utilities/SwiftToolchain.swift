import Foundation

/// Discovers and interacts with the local Swift toolchain.
struct SwiftToolchain: Sendable {

    /// Validates that a Swift toolchain is available on the system.
    ///
    /// - Throws: ``CLIError/toolchainNotFound`` if `swift` is not on the PATH.
    static func validate() throws {
        let result = try ProcessRunner.run("swift", arguments: ["--version"])
        guard result.succeeded else {
            throw CLIError.toolchainNotFound
        }
    }

    /// Returns the Swift version string (e.g. `"6.2"`).
    ///
    /// - Throws: ``CLIError/toolchainNotFound`` if `swift` is not available.
    static func version() throws -> String {
        let result = try ProcessRunner.run("swift", arguments: ["--version"])
        guard result.succeeded else {
            throw CLIError.toolchainNotFound
        }
        return parseVersion(from: result.stdout) ?? result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Runs `swift build` in the given directory.
    ///
    /// - Parameters:
    ///   - release: Whether to build in release configuration.
    ///   - directory: The project directory. Defaults to the current directory.
    /// - Throws: An error if the Swift process cannot be launched.
    /// - Returns: A ``BuildResult`` with success status, output, and parsed diagnostics.
    static func build(release: Bool = false, in directory: String? = nil) throws -> BuildResult {
        var arguments = ["build"]
        if release {
            arguments += ["-c", "release"]
        }

        let result = try ProcessRunner.run("swift", arguments: arguments, in: directory)
        let diagnostics = CompilerDiagnostic.parse(result.stderr)

        return BuildResult(
            succeeded: result.succeeded,
            output: result.stdout + result.stderr,
            errors: diagnostics
        )
    }

    /// Streams `swift build` output line-by-line.
    ///
    /// - Parameters:
    ///   - release: Whether to build in release configuration.
    ///   - directory: The project directory.
    ///   - onLine: Called for each line of build output.
    /// - Throws: An error if the Swift process cannot be launched.
    /// - Returns: A ``BuildResult`` with success status and parsed diagnostics.
    static func buildStreaming(
        release: Bool = false,
        in directory: String? = nil,
        onLine: @escaping @Sendable (String) -> Void
    ) throws -> BuildResult {
        var arguments = ["build"]
        if release {
            arguments += ["-c", "release"]
        }

        let collected = LockedValue("")

        let exitCode = try ProcessRunner.stream(
            "swift",
            arguments: arguments,
            in: directory
        ) { line in
            collected.withLock { $0 += line + "\n" }
            onLine(line)
        }

        let output = collected.withLock { $0 }
        let diagnostics = CompilerDiagnostic.parse(output)

        return BuildResult(
            succeeded: exitCode == 0,
            output: output,
            errors: diagnostics
        )
    }

    /// Returns the path to the build products directory.
    ///
    /// - Parameters:
    ///   - release: Whether to query for the release configuration.
    ///   - directory: The project directory.
    /// - Throws: ``CLIError/processFailure(command:exitCode:stderr:)`` if the query fails.
    /// - Returns: The absolute path to the binary output directory.
    static func binPath(release: Bool = false, in directory: String? = nil) throws -> String {
        var arguments = ["build", "--show-bin-path"]
        if release {
            arguments += ["-c", "release"]
        }

        let result = try ProcessRunner.run("swift", arguments: arguments, in: directory)
        guard result.succeeded else {
            throw CLIError.processFailure(
                command: "swift build --show-bin-path",
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds the executable product in the build directory.
    ///
    /// Scans `Package.swift` for `.executableTarget` names and checks the
    /// bin path for a matching binary. Falls back to the project directory name.
    ///
    /// - Parameters:
    ///   - directory: The project directory.
    ///   - release: Whether to look in the release bin path.
    /// - Throws: ``CLIError/fileSystemError(_:)`` if no executable is found.
    /// - Returns: The absolute path to the built executable.
    static func findExecutable(in directory: String? = nil, release: Bool = false) throws -> String {
        let projectDir = directory ?? FileManager.default.currentDirectoryPath
        let binDirectory = try binPath(release: release, in: directory)
        let candidates = executableCandidates(in: projectDir)
        let fm = FileManager.default

        for candidate in candidates {
            let path = "\(binDirectory)/\(candidate)"
            if fm.isExecutableFile(atPath: path) {
                return path
            }
        }

        throw CLIError.fileSystemError("No executable found in \(binDirectory)")
    }

    static func parseVersion(from output: String) -> String? {
        guard let range = output.range(of: #"Swift version (\d+\.\d+(\.\d+)?)"#, options: .regularExpression) else {
            return nil
        }
        let match = output[range]
        return match.replacingOccurrences(of: "Swift version ", with: "")
    }

    private static func executableCandidates(in directory: String) -> [String] {
        var candidates: [String] = []

        let packagePath = "\(directory)/Package.swift"
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            let pattern = #"\.executableTarget\(\s*name:\s*"([^"]+)""#
            if let regex = try? NSRegularExpression(pattern: pattern),
                let match = regex.firstMatch(
                    in: content,
                    range: NSRange(content.startIndex..., in: content)
                ),
                let nameRange = Range(match.range(at: 1), in: content)
            {
                candidates.append(String(content[nameRange]))
            }
        }

        let directoryName = URL(fileURLWithPath: directory).lastPathComponent
        if !candidates.contains(directoryName) {
            candidates.append(directoryName)
        }

        return candidates
    }
}

/// The result of a Swift build operation.
struct BuildResult: Sendable {
    /// Whether the build succeeded.
    let succeeded: Bool

    /// The combined stdout and stderr output.
    let output: String

    /// Parsed compiler diagnostics extracted from the output.
    let errors: [CompilerDiagnostic]
}
