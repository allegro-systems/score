import ArgumentParser
import Foundation
import Noora

struct DeployCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "deploy",
        abstract: "Deploy a Score app to Stage"
    )

    @Option(help: "Stage host (SSH destination)")
    var host: String

    @Option(help: "App owner username")
    var user: String

    @Option(help: "Application name")
    var app: String

    @Option(help: "App kind: score, static, swift-server")
    var kind: String = "score"

    @Option(help: "Custom domains (comma-separated)")
    var domains: String?

    @Flag(help: "Run score build before deploying")
    var build: Bool = false

    @Option(help: "Path to build artifact directory")
    var artifact: String = ".score"

    var normalizedKind: String {
        switch kind {
        case "static": return "static_site"
        case "swift-server": return "swift_server"
        default: return kind
        }
    }

    func validate() throws {
        guard FileManager.default.fileExists(atPath: artifact) else {
            throw ValidationError("Artifact directory '\(artifact)' does not exist. Run 'score build' first.")
        }
    }

    func run() async throws {
        if build {
            noora.info("Building...")
            let buildResult = try runProcess("/usr/bin/swift", arguments: ["build", "-c", "release"])
            guard buildResult == 0 else { throw ExitCode(buildResult) }
        }

        let remoteTemp = "/tmp/stage-deploy-\(UUID().uuidString)"

        noora.info("Uploading artifact to \(host)...")
        let rsyncResult = try runProcess(
            "/usr/bin/rsync",
            arguments: ["-az", "--delete", "\(artifact)/", "\(host):\(remoteTemp)/"]
        )
        guard rsyncResult == 0 else {
            noora.warning(.alert("rsync failed", takeaway: "Check your SSH connection to \(host)"))
            throw ExitCode(rsyncResult)
        }

        noora.info("Deploying \(user)/\(app) on Stage...")
        var deployArgs = ["stage-manager", "deploy", user, app, "--artifact", remoteTemp, "--kind", normalizedKind]
        if let domains {
            deployArgs += ["--domains", domains]
        }
        let deployResult = try runProcess("/usr/bin/ssh", arguments: [host] + deployArgs)

        _ = try? runProcess("/usr/bin/ssh", arguments: [host, "rm", "-rf", remoteTemp])

        guard deployResult == 0 else {
            noora.warning(.alert("Deploy failed", takeaway: "Check stage-manager logs on \(host)"))
            throw ExitCode(deployResult)
        }

        noora.success("Deployed \(user)/\(app) successfully")
    }

    @discardableResult
    private func runProcess(_ executable: String, arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
