import Testing

@testable import ScoreCLI

@Test func parseVersionFromOutput() {
    let output = "Swift version 6.2 (swift-6.2-RELEASE)"
    let version = SwiftToolchain.parseVersion(from: output)

    #expect(version == "6.2")
}

@Test func parseVersionWithPatchNumber() {
    let output = "Swift version 5.10.1 (swift-5.10.1-RELEASE)"
    let version = SwiftToolchain.parseVersion(from: output)

    #expect(version == "5.10.1")
}

@Test func parseVersionFromMultiLineOutput() {
    let output = """
        Apple Swift version 6.2 (swiftlang-6.2.0.6.11 clang-1700.3.7.6)
        Target: arm64-apple-macosx15.0
        """
    let version = SwiftToolchain.parseVersion(from: output)

    #expect(version == "6.2")
}

@Test func parseVersionReturnsNilForGarbage() {
    let version = SwiftToolchain.parseVersion(from: "not a version string")
    #expect(version == nil)
}

@Test func parseVersionReturnsNilForEmpty() {
    let version = SwiftToolchain.parseVersion(from: "")
    #expect(version == nil)
}

@Test func validateSucceedsWithInstalledToolchain() throws {
    try SwiftToolchain.validate()
}

@Test func versionReturnsNonEmptyString() throws {
    let version = try SwiftToolchain.version()
    #expect(!version.isEmpty)
}
