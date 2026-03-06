import Foundation
import Testing

@testable import ScoreCLI

@Test func clonerThrowsWhenDestinationExists() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-cloner-test-\(ProcessInfo.processInfo.processIdentifier)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let cloner = TemplateCloner()
    #expect(throws: CLIError.self) {
        try cloner.clone(template: .minimal, to: tempDir.path)
    }
}

@Test func clonerRepoURL() {
    #expect(TemplateCloner.repoURL.contains("allegro-systems/score"))
}
