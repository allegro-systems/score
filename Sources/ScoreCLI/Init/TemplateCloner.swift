import Foundation

/// Clones a template into a new project directory.
///
/// App templates are fetched from the Score repository's `Examples/` directory
/// via sparse checkout. The plugin template is cloned from a dedicated repo.
struct TemplateCloner: Sendable {

    static let repoURL = "https://github.com/allegro-systems/score"
    static let pluginTemplateRepoURL = "https://github.com/allegro-systems/score-plugin-template"

    /// Clones the specified template into the target directory.
    ///
    /// - Parameters:
    ///   - template: The template to clone.
    ///   - destination: The absolute path to write the project into.
    /// - Throws: ``CLIError`` if the clone fails or the destination already exists.
    func clone(template: Template, to destination: String) throws {
        let fileManager = FileManager.default

        guard !fileManager.fileExists(atPath: destination) else {
            throw CLIError.directoryExists(destination)
        }

        if template.isPlugin {
            try clonePluginTemplate(to: destination)
        } else {
            try cloneAppTemplate(template, to: destination)
        }
    }

    // MARK: - Private

    private func clonePluginTemplate(to destination: String) throws {
        let result = try ProcessRunner.run(
            "git",
            arguments: ["clone", "--depth", "1", Self.pluginTemplateRepoURL, destination])

        guard result.succeeded else {
            throw CLIError.processFailure(
                command: "git clone",
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }

        // Remove the cloned .git directory so the user starts fresh.
        try? FileManager.default.removeItem(atPath: "\(destination)/.git")
    }

    private func cloneAppTemplate(_ template: Template, to destination: String) throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("score-init-\(ProcessInfo.processInfo.processIdentifier)")
            .path

        defer { try? fileManager.removeItem(atPath: tempDir) }

        let cloneResult = try ProcessRunner.run(
            "git",
            arguments: [
                "clone", "--depth", "1", "--filter=blob:none", "--sparse",
                Self.repoURL, tempDir,
            ])

        guard cloneResult.succeeded else {
            throw CLIError.processFailure(
                command: "git clone",
                exitCode: cloneResult.exitCode,
                stderr: cloneResult.stderr
            )
        }

        let sparseResult = try ProcessRunner.run(
            "git",
            arguments: [
                "-C", tempDir,
                "sparse-checkout", "set", "Examples/\(template.directoryName)",
            ])

        guard sparseResult.succeeded else {
            throw CLIError.processFailure(
                command: "git sparse-checkout",
                exitCode: sparseResult.exitCode,
                stderr: sparseResult.stderr
            )
        }

        let sourcePath = "\(tempDir)/Examples/\(template.directoryName)"

        guard fileManager.fileExists(atPath: sourcePath) else {
            throw CLIError.unknownTemplate(template.rawValue)
        }

        try fileManager.copyItem(atPath: sourcePath, toPath: destination)
    }
}
