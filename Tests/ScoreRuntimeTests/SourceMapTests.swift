import Testing

@testable import ScoreRuntime

@Test func sourceMapBuilderProducesValidV3JSON() {
    var builder = SourceMap.Builder(file: "page.js")
    builder.addMapping(
        generatedLine: 0, generatedColumn: 0,
        source: "HomePage.swift", sourceLine: 10, sourceColumn: 4,
        name: "count"
    )
    let json = builder.build()

    #expect(json.contains("\"version\":3"))
    #expect(json.contains("\"file\":\"page.js\""))
    #expect(json.contains("\"sources\":[\"HomePage.swift\"]"))
    #expect(json.contains("\"names\":[\"count\"]"))
    #expect(json.contains("\"mappings\":"))
}

@Test func sourceMapBuilderEmptyMappings() {
    let builder = SourceMap.Builder(file: "empty.js")
    let json = builder.build()

    #expect(json.contains("\"mappings\":\"\""))
    #expect(json.contains("\"sources\":[]"))
    #expect(json.contains("\"names\":[]"))
}

@Test func sourceMapBuilderMultipleSources() {
    var builder = SourceMap.Builder(file: "bundle.js")
    builder.addMapping(
        generatedLine: 0, generatedColumn: 0,
        source: "FileA.swift", sourceLine: 0, sourceColumn: 0
    )
    builder.addMapping(
        generatedLine: 1, generatedColumn: 0,
        source: "FileB.swift", sourceLine: 5, sourceColumn: 0
    )
    let json = builder.build()

    #expect(json.contains("\"FileA.swift\""))
    #expect(json.contains("\"FileB.swift\""))
}

@Test func sourceMapBuilderMultipleLines() {
    var builder = SourceMap.Builder(file: "multi.js")
    builder.addMapping(
        generatedLine: 0, generatedColumn: 0,
        source: "Test.swift", sourceLine: 0, sourceColumn: 0
    )
    builder.addMapping(
        generatedLine: 2, generatedColumn: 0,
        source: "Test.swift", sourceLine: 2, sourceColumn: 0
    )
    let json = builder.build()

    // Semicolons separate lines in source map mappings.
    let mappingsMatch = json.range(of: "\"mappings\":\"[^\"]*;[^\"]*\"", options: .regularExpression)
    #expect(mappingsMatch != nil)
}

@Test func vlqEncodeZero() {
    let result = SourceMap.vlqEncode(0)
    #expect(result == "A")  // 0 -> VLQ 0 -> base64 'A'
}

@Test func vlqEncodePositive() {
    let result = SourceMap.vlqEncode(1)
    #expect(result == "C")  // 1 -> shifted 2 -> VLQ digit 2 -> 'C'
}

@Test func vlqEncodeNegative() {
    let result = SourceMap.vlqEncode(-1)
    #expect(result == "D")  // -1 -> shifted 3 -> VLQ digit 3 -> 'D'
}

@Test func sourceMapEscapesSpecialCharsInFilename() {
    var builder = SourceMap.Builder(file: "page \"script\".js")
    builder.addMapping(
        generatedLine: 0, generatedColumn: 0,
        source: "My File.swift", sourceLine: 0, sourceColumn: 0
    )
    let json = builder.build()

    #expect(json.contains("page \\\"script\\\".js"))
    #expect(json.contains("My File.swift"))
}
