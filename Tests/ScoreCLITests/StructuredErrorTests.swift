import Foundation
import Testing

@testable import ScoreCLI

@Test func structuredErrorEncodesToJSON() throws {
    let error = StructuredError(
        code: "E001",
        message: "Something failed",
        stage: "build",
        file: "App.swift",
        line: 42,
        column: 8,
        details: ["detail one", "detail two"]
    )

    let json = try error.json()
    #expect(json.contains("\"code\" : \"E001\""))
    #expect(json.contains("\"message\" : \"Something failed\""))
    #expect(json.contains("\"stage\" : \"build\""))
    #expect(json.contains("\"file\" : \"App.swift\""))
    #expect(json.contains("\"line\" : 42"))
    #expect(json.contains("\"column\" : 8"))
    #expect(json.contains("detail one"))
    #expect(json.contains("detail two"))
}

@Test func structuredErrorRoundTrips() throws {
    let original = StructuredError(
        code: "E002",
        message: "Round trip test"
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(StructuredError.self, from: data)

    #expect(decoded.code == original.code)
    #expect(decoded.message == original.message)
    #expect(decoded.stage == nil)
    #expect(decoded.file == nil)
    #expect(decoded.line == nil)
    #expect(decoded.column == nil)
    #expect(decoded.details.isEmpty)
}

@Test func structuredErrorJSONHasSortedKeys() throws {
    let error = StructuredError(code: "E003", message: "test")
    let json = try error.json()

    let codeIndex = json.range(of: "\"code\"")!.lowerBound
    let messageIndex = json.range(of: "\"message\"")!.lowerBound
    #expect(codeIndex < messageIndex)
}
