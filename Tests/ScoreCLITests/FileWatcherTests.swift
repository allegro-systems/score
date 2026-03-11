import Foundation
import Testing

@testable import ScoreCLI

@Test func buildSnapshotFindsSwiftFiles() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-watcher-test-\(ProcessInfo.processInfo.processIdentifier)")
        .path
    let fm = FileManager.default

    try fm.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(atPath: tempDir) }

    let swiftFile = "\(tempDir)/Test.swift"
    try "let x = 1".write(toFile: swiftFile, atomically: true, encoding: .utf8)

    let txtFile = "\(tempDir)/notes.txt"
    try "hello".write(toFile: txtFile, atomically: true, encoding: .utf8)

    let watcher = FileWatcher(directories: [tempDir], extensions: ["swift"])
    let snapshot = watcher.snapshot()

    #expect(snapshot[swiftFile] != nil)
    #expect(snapshot[txtFile] == nil)
}

@Test func buildSnapshotFindsFilesRecursively() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-watcher-recursive-\(ProcessInfo.processInfo.processIdentifier)")
        .path
    let fm = FileManager.default

    try fm.createDirectory(atPath: "\(tempDir)/sub", withIntermediateDirectories: true)
    defer { try? fm.removeItem(atPath: tempDir) }

    let rootFile = "\(tempDir)/Root.swift"
    try "// root".write(toFile: rootFile, atomically: true, encoding: .utf8)

    let nestedFile = "\(tempDir)/sub/Nested.swift"
    try "// nested".write(toFile: nestedFile, atomically: true, encoding: .utf8)

    let watcher = FileWatcher(directories: [tempDir], extensions: ["swift"])
    let snapshot = watcher.snapshot()

    #expect(snapshot.count == 2)
    #expect(snapshot[rootFile] != nil)
    #expect(snapshot[nestedFile] != nil)
}

@Test func diffDetectsNewFiles() {
    let watcher = FileWatcher(directories: [], extensions: ["swift"])

    let old: [String: Date] = [:]
    let new: [String: Date] = ["a.swift": Date()]

    let changed = watcher.diff(old: old, new: new)
    #expect(changed == ["a.swift"])
}

@Test func diffDetectsRemovedFiles() {
    let watcher = FileWatcher(directories: [], extensions: ["swift"])

    let old: [String: Date] = ["a.swift": Date()]
    let new: [String: Date] = [:]

    let changed = watcher.diff(old: old, new: new)
    #expect(changed == ["a.swift"])
}

@Test func diffDetectsModifiedFiles() {
    let watcher = FileWatcher(directories: [], extensions: ["swift"])

    let earlier = Date(timeIntervalSince1970: 1000)
    let later = Date(timeIntervalSince1970: 2000)

    let old: [String: Date] = ["a.swift": earlier]
    let new: [String: Date] = ["a.swift": later]

    let changed = watcher.diff(old: old, new: new)
    #expect(changed == ["a.swift"])
}

@Test func diffReturnsEmptyWhenUnchanged() {
    let watcher = FileWatcher(directories: [], extensions: ["swift"])

    let now = Date()
    let old: [String: Date] = ["a.swift": now, "b.swift": now]
    let new: [String: Date] = ["a.swift": now, "b.swift": now]

    let changed = watcher.diff(old: old, new: new)
    #expect(changed.isEmpty)
}

@Test func buildSnapshotReturnsEmptyForMissingDirectory() {
    let watcher = FileWatcher(
        directories: ["/nonexistent/path/that/does/not/exist"],
        extensions: ["swift"]
    )
    let snapshot = watcher.snapshot()
    #expect(snapshot.isEmpty)
}

@Test func multipleExtensions() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("score-watcher-ext-\(ProcessInfo.processInfo.processIdentifier)")
        .path
    let fm = FileManager.default

    try fm.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(atPath: tempDir) }

    try "code".write(toFile: "\(tempDir)/a.swift", atomically: true, encoding: .utf8)
    try "{}".write(toFile: "\(tempDir)/b.json", atomically: true, encoding: .utf8)
    try "data".write(toFile: "\(tempDir)/c.txt", atomically: true, encoding: .utf8)

    let watcher = FileWatcher(directories: [tempDir], extensions: ["swift", "json"])
    let snapshot = watcher.snapshot()

    #expect(snapshot.count == 2)
}
