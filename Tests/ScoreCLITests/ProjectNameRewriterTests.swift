import Foundation
import Testing

@testable import ScoreCLI

@Test func rewriterReplacesLocalPathDependency() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let packageContent = """
        // swift-tools-version: 6.2
        import PackageDescription
        let package = Package(
            name: "Minimal",
            dependencies: [
                .package(path: "../../"),
            ],
            targets: [
                .executableTarget(name: "Minimal", dependencies: ["Score"]),
            ]
        )
        """
    try packageContent.write(
        to: tmp.appendingPathComponent("Package.swift"),
        atomically: true,
        encoding: .utf8
    )

    let rewriter = ProjectNameRewriter()
    try rewriter.rewrite(at: tmp.path, projectName: "MyApp")

    let rewritten = try String(contentsOfFile: tmp.appendingPathComponent("Package.swift").path, encoding: .utf8)
    #expect(rewritten.contains("allegro-systems/score.git"))
    #expect(!rewritten.contains("path: \"../../\""))
    #expect(rewritten.contains("\"MyApp\""))
    #expect(!rewritten.contains("\"Minimal\""))
}

@Test func rewriterRenamesPluginTemplate() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    // Set up plugin template structure.
    let sourcesDir = tmp.appendingPathComponent("Sources/ScorePluginTemplate")
    let testsDir = tmp.appendingPathComponent("Tests/ScorePluginTemplateTests")
    try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: testsDir, withIntermediateDirectories: true)

    let packageContent = """
        // swift-tools-version: 6.2
        import PackageDescription
        let package = Package(
            name: "ScorePluginTemplate",
            products: [.library(name: "ScorePluginTemplate", targets: ["ScorePluginTemplate"])],
            dependencies: [.package(url: "https://github.com/allegro-systems/score.git", from: "0.1.0")],
            targets: [
                .target(name: "ScorePluginTemplate", dependencies: [.product(name: "Score", package: "score")]),
                .testTarget(name: "ScorePluginTemplateTests", dependencies: ["ScorePluginTemplate"]),
            ]
        )
        """
    try packageContent.write(to: tmp.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

    let pluginSource = """
        import Score
        public struct ScorePluginTemplate: ScorePlugin {
            public let name = "ScorePluginTemplate"
            public init() {}
        }
        """
    try pluginSource.write(to: sourcesDir.appendingPathComponent("Plugin.swift"), atomically: true, encoding: .utf8)

    let testSource = """
        import Testing
        @testable import ScorePluginTemplate
        struct ScorePluginTemplateTests {
            @Test func pluginName() {
                let plugin = ScorePluginTemplate()
                #expect(plugin.name == "ScorePluginTemplate")
            }
        }
        """
    try testSource.write(to: testsDir.appendingPathComponent("PluginTests.swift"), atomically: true, encoding: .utf8)

    let rewriter = ProjectNameRewriter()
    try rewriter.rewrite(at: tmp.path, projectName: "ScoreStripe", isPlugin: true)

    // Package.swift should use the new name.
    let rewritten = try String(contentsOfFile: tmp.appendingPathComponent("Package.swift").path, encoding: .utf8)
    #expect(rewritten.contains("ScoreStripe"))
    #expect(!rewritten.contains("ScorePluginTemplate"))

    // Source directory should be renamed.
    #expect(FileManager.default.fileExists(atPath: tmp.appendingPathComponent("Sources/ScoreStripe").path))
    #expect(!FileManager.default.fileExists(atPath: sourcesDir.path))

    // Test directory should be renamed.
    #expect(FileManager.default.fileExists(atPath: tmp.appendingPathComponent("Tests/ScoreStripeTests").path))
    #expect(!FileManager.default.fileExists(atPath: testsDir.path))

    // Source file contents should be renamed.
    let pluginRewritten = try String(
        contentsOfFile: tmp.appendingPathComponent("Sources/ScoreStripe/Plugin.swift").path, encoding: .utf8)
    #expect(pluginRewritten.contains("ScoreStripe"))
    #expect(!pluginRewritten.contains("ScorePluginTemplate"))
}

@Test func rewriterRemovesGeneratedDirectory() throws {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tmp) }

    let generatedDir = tmp.appendingPathComponent("Generated")
    try FileManager.default.createDirectory(at: generatedDir, withIntermediateDirectories: true)
    try "test".write(to: generatedDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

    let packageContent = """
        // swift-tools-version: 6.2
        import PackageDescription
        let package = Package(name: "Test", dependencies: [.package(path: "../../")])
        """
    try packageContent.write(
        to: tmp.appendingPathComponent("Package.swift"),
        atomically: true,
        encoding: .utf8
    )

    let rewriter = ProjectNameRewriter()
    try rewriter.rewrite(at: tmp.path, projectName: "Test")

    #expect(!FileManager.default.fileExists(atPath: generatedDir.path))
}
