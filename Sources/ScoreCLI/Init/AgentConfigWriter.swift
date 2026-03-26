import Foundation

/// Renames `AGENTS.md` to the appropriate filename for a specific AI coding agent.
///
/// Supported agents:
/// - `claude` — Renames `AGENTS.md` to `CLAUDE.md`
struct AgentConfigWriter {

    private init() {}

    private static let agentFileNames: [String: String] = [
        "claude": "CLAUDE.md"
    ]

    /// Renames `AGENTS.md` to the agent-specific filename.
    ///
    /// - Parameters:
    ///   - agent: The agent identifier (e.g. `"claude"`).
    ///   - directory: The project root directory.
    /// - Throws: ``CLIError`` if the agent is unknown, or a file system error.
    static func write(agent: String, at directory: String) throws {
        guard let targetName = agentFileNames[agent.lowercased()] else {
            throw CLIError.unknownAgent(agent)
        }

        let sourcePath = "\(directory)/AGENTS.md"
        let targetPath = "\(directory)/\(targetName)"
        let fm = FileManager.default

        guard fm.fileExists(atPath: sourcePath) else { return }
        try fm.moveItem(atPath: sourcePath, toPath: targetPath)
    }
}
