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
