import Testing

@testable import ScoreCLI

@Test func parseSingleError() {
    let output = "/path/to/File.swift:10:5: error: use of unresolved identifier 'foo'"
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics[0].file == "/path/to/File.swift")
    #expect(diagnostics[0].line == 10)
    #expect(diagnostics[0].column == 5)
    #expect(diagnostics[0].severity == .error)
    #expect(diagnostics[0].message == "use of unresolved identifier 'foo'")
}

@Test func parseWarning() {
    let output = "Sources/App.swift:42:13: warning: unused variable 'x'"
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics[0].severity == .warning)
    #expect(diagnostics[0].message == "unused variable 'x'")
}

@Test func parseNote() {
    let output = "Sources/App.swift:1:1: note: protocol declared here"
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics[0].severity == .note)
}

@Test func parseMultipleDiagnostics() {
    let output = """
        Sources/A.swift:1:1: error: first error
        Sources/B.swift:2:3: warning: first warning
        Sources/A.swift:5:10: error: second error
        """
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 3)
    #expect(diagnostics[0].severity == .error)
    #expect(diagnostics[1].severity == .warning)
    #expect(diagnostics[2].severity == .error)
}

@Test func parseIgnoresNonDiagnosticLines() {
    let output = """
        Building for debugging...
        [1/5] Compiling Module File.swift
        Sources/App.swift:10:5: error: something broke
        Build complete! (0.42s)
        """
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics[0].message == "something broke")
}

@Test func parseEmptyOutput() {
    let diagnostics = CompilerDiagnostic.parse("")
    #expect(diagnostics.isEmpty)
}

@Test func parseGarbageInput() {
    let diagnostics = CompilerDiagnostic.parse("this is not a diagnostic")
    #expect(diagnostics.isEmpty)
}

@Test func toStructuredErrorConversion() {
    let diagnostic = CompilerDiagnostic(
        file: "Sources/App.swift",
        line: 42,
        column: 13,
        severity: .error,
        message: "cannot find type 'Foo' in scope"
    )

    let structured = diagnostic.toStructuredError()

    #expect(structured.code == "compile_error")
    #expect(structured.message == "cannot find type 'Foo' in scope")
    #expect(structured.stage == "build")
    #expect(structured.file == "Sources/App.swift")
    #expect(structured.line == 42)
    #expect(structured.column == 13)
}

@Test func warningToStructuredErrorUsesCorrectCode() {
    let diagnostic = CompilerDiagnostic(
        file: "test.swift",
        line: 1,
        column: 1,
        severity: .warning,
        message: "unused"
    )

    #expect(diagnostic.toStructuredError().code == "compile_warning")
}

@Test func diagnosticEquality() {
    let a = CompilerDiagnostic(file: "a.swift", line: 1, column: 1, severity: .error, message: "msg")
    let b = CompilerDiagnostic(file: "a.swift", line: 1, column: 1, severity: .error, message: "msg")
    let c = CompilerDiagnostic(file: "b.swift", line: 1, column: 1, severity: .error, message: "msg")

    #expect(a == b)
    #expect(a != c)
}

@Test func parseColonInMessage() {
    let output = "File.swift:1:1: error: type 'A' does not conform to protocol 'B': missing method"
    let diagnostics = CompilerDiagnostic.parse(output)

    #expect(diagnostics.count == 1)
    #expect(diagnostics[0].message == "type 'A' does not conform to protocol 'B': missing method")
}
