import Foundation
import ScoreCore
import StageKit

/// Emits the application manifest to stdout using the shared `StageKit.AppManifest` type.
///
/// Used by `stage-manager` at deploy time to discover routes, capabilities, and build metadata
/// without running the server. Both sides share the exact same Swift type — no mirror, no drift.
///
/// The wire format is binary property list (`PropertyListEncoder` with `.binary` format).
/// This is more compact and faster than JSON, and round-trips perfectly for all Codable types.
/// Both sides are Swift, so there's no need for a human-readable interchange format.
enum ManifestEmitter {

    static func emit(application: some Application) throws {
        let manifest = buildManifest(from: application)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(manifest)
        FileHandle.standardOutput.write(data)
    }

    private static func buildManifest(from app: some Application) -> AppManifest {
        let controllers = app.controllers.map { controller in
            let methods = Array(Set(controller.routes.map { $0.method.rawValue })).sorted()
            return AppManifest.ControllerRoute(prefix: controller.base, methods: methods)
        }

        var capabilities: Set<String> = ["static"]
        if !app.controllers.isEmpty {
            capabilities.insert("server_runtime")
        }

        let build = AppManifest.Build(
            score: scoreVersion,
            swift: swiftVersion,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            commit: gitCommit
        )

        return AppManifest(
            build: build,
            capabilities: capabilities,
            controllers: controllers
        )
    }

    // MARK: - Build Info

    private static let scoreVersion = "0.1.0"

    private static var swiftVersion: String {
        #if swift(>=6.2)
        "6.2"
        #elseif swift(>=6.1)
        "6.1"
        #elseif swift(>=6.0)
        "6.0"
        #else
        "unknown"
        #endif
    }

    private static var gitCommit: String {
        ProcessInfo.processInfo.environment["SCORE_BUILD_COMMIT"] ?? "unknown"
    }
}
