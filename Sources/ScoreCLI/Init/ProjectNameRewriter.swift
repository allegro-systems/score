import Foundation

/// Rewrites a cloned template to use the user's project name.
///
/// Performs two transformations:
/// 1. Replaces the local path dependency in `Package.swift` with a versioned registry dependency.
/// 2. Renames the executable target to the user's project name.
struct ProjectNameRewriter: Sendable {

    /// Rewrites the cloned template at the given path.
    ///
    /// - Parameters:
    ///   - path: The root directory of the cloned project.
    ///   - projectName: The user's chosen project name.
    /// - Throws: An error if files cannot be read or written.
    func rewrite(at path: String, projectName: String) throws {
        try rewritePackageSwift(at: path, projectName: projectName)
        try removeGeneratedDirectory(at: path)
    }

    private func rewritePackageSwift(at path: String, projectName: String) throws {
        let packagePath = "\(path)/Package.swift"
        var content = try String(contentsOfFile: packagePath, encoding: .utf8)

        content = content.replacingOccurrences(
            of: ".package(path: \"../../\")",
            with: ".package(url: \"https://github.com/allegro-systems/score.git\", from: \"0.1.0\")"
        )

        content = content.replacingOccurrences(
            of: ".package(path: \"../..\")",
            with: ".package(url: \"https://github.com/allegro-systems/score.git\", from: \"0.1.0\")"
        )

        let templateNames = Template.allCases.map(\.directoryName)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }

        for templateName in templateNames {
            content = content.replacingOccurrences(of: "\"\(templateName)\"", with: "\"\(projectName)\"")
        }

        try content.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    private func removeGeneratedDirectory(at path: String) throws {
        let generatedPath = "\(path)/Generated"
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: generatedPath) {
            try fileManager.removeItem(atPath: generatedPath)
        }
    }
}
