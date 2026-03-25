import Foundation

/// Rewrites a cloned template to use the user's project name.
///
/// For app templates: replaces the local path dependency with a versioned
/// dependency and renames target references.
///
/// For plugin templates: renames `ScorePluginTemplate` throughout all source
/// files, `Package.swift`, `README.md`, and renames source/test directories.
struct ProjectNameRewriter: Sendable {

    private static let pluginPlaceholder = "ScorePluginTemplate"

    /// Rewrites the cloned template at the given path.
    ///
    /// - Parameters:
    ///   - path: The root directory of the cloned project.
    ///   - projectName: The user's chosen project name.
    ///   - isPlugin: Whether this is a plugin template.
    /// - Throws: An error if files cannot be read or written.
    func rewrite(at path: String, projectName: String, isPlugin: Bool = false) throws {
        if isPlugin {
            try rewritePluginTemplate(at: path, projectName: projectName)
        } else {
            try rewriteAppTemplate(at: path, projectName: projectName)
        }
    }

    // MARK: - Plugin Templates

    private func rewritePluginTemplate(at path: String, projectName: String) throws {
        let placeholder = Self.pluginPlaceholder
        let fm = FileManager.default

        // Replace placeholder in all text files.
        try replaceInTextFiles(at: path, replacing: placeholder, with: projectName)

        // Rename source directory.
        let oldSources = "\(path)/Sources/\(placeholder)"
        let newSources = "\(path)/Sources/\(projectName)"
        if fm.fileExists(atPath: oldSources) {
            try fm.moveItem(atPath: oldSources, toPath: newSources)
        }

        // Rename test directory.
        let oldTests = "\(path)/Tests/\(placeholder)Tests"
        let newTests = "\(path)/Tests/\(projectName)Tests"
        if fm.fileExists(atPath: oldTests) {
            try fm.moveItem(atPath: oldTests, toPath: newTests)
        }
    }

    // MARK: - App Templates

    private func rewriteAppTemplate(at path: String, projectName: String) throws {
        let packagePath = "\(path)/Package.swift"
        var content = try String(contentsOfFile: packagePath, encoding: .utf8)

        // Replace local path dependencies with versioned registry dependency.
        let registryDep = ".package(url: \"https://github.com/allegro-systems/score.git\", from: \"0.1.0\")"
        content = content.replacingOccurrences(of: ".package(path: \"../../\")", with: registryDep)
        content = content.replacingOccurrences(of: ".package(path: \"../..\")", with: registryDep)

        // Replace template target names with the user's project name.
        let templateNames = Template.allCases
            .filter { !$0.isPlugin }
            .map(\.directoryName)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }

        for templateName in templateNames {
            content = content.replacingOccurrences(of: "\"\(templateName)\"", with: "\"\(projectName)\"")
        }

        try content.write(toFile: packagePath, atomically: true, encoding: .utf8)

        // Clean up generated artifacts.
        let generatedPath = "\(path)/Generated"
        if FileManager.default.fileExists(atPath: generatedPath) {
            try FileManager.default.removeItem(atPath: generatedPath)
        }
    }

    // MARK: - Helpers

    private func replaceInTextFiles(at directory: String, replacing old: String, with new: String) throws {
        let fm = FileManager.default
        let textExtensions: Set<String> = ["swift", "md", "toml", "json", "yml", "yaml", "txt"]

        guard let enumerator = fm.enumerator(atPath: directory) else { return }
        while let relativePath = enumerator.nextObject() as? String {
            let ext = (relativePath as NSString).pathExtension
            let filename = (relativePath as NSString).lastPathComponent

            guard textExtensions.contains(ext) || filename == "Package.swift" else { continue }

            let fullPath = "\(directory)/\(relativePath)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue else { continue }

            var content = try String(contentsOfFile: fullPath, encoding: .utf8)
            guard content.contains(old) else { continue }
            content = content.replacingOccurrences(of: old, with: new)
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
        }
    }
}
