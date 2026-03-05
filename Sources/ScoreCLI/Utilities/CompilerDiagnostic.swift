import Foundation

/// A parsed Swift compiler diagnostic (error, warning, or note).
struct CompilerDiagnostic: Sendable, Equatable {

    /// The severity of the diagnostic.
    enum Severity: String, Sendable, Equatable {
        case error
        case warning
        case note
    }

    /// The source file path.
    let file: String

    /// The line number in the source file.
    let line: Int

    /// The column number in the source file.
    let column: Int

    /// The diagnostic severity.
    let severity: Severity

    /// The diagnostic message.
    let message: String

    /// Parses Swift compiler output into an array of diagnostics.
    ///
    /// Matches lines in the format: `path/file.swift:line:column: severity: message`
    ///
    /// - Parameter output: The raw compiler stderr output.
    /// - Returns: An array of parsed diagnostics.
    static func parse(_ output: String) -> [CompilerDiagnostic] {
        var diagnostics: [CompilerDiagnostic] = []

        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            if let diagnostic = parseLine(String(line)) {
                diagnostics.append(diagnostic)
            }
        }

        return diagnostics
    }

    /// Converts this diagnostic to a ``StructuredError`` for JSON output.
    func toStructuredError() -> StructuredError {
        StructuredError(
            code: "compile_\(severity.rawValue)",
            message: message,
            stage: "build",
            file: file,
            line: line,
            column: column
        )
    }

    private static func parseLine(_ line: String) -> CompilerDiagnostic? {
        let components = line.split(separator: ":", maxSplits: 4)
        guard components.count >= 5 else { return nil }

        let filePart: String
        let linePart: Substring
        let columnPart: Substring
        let severityPart: Substring
        let messagePart: Substring

        if components[0].count == 1, components[0].allSatisfy(\.isLetter) {
            let windowsComponents = line.split(separator: ":", maxSplits: 5)
            guard windowsComponents.count >= 6 else { return nil }
            filePart = String(windowsComponents[0]) + ":" + String(windowsComponents[1])
            linePart = windowsComponents[2]
            columnPart = windowsComponents[3]
            severityPart = windowsComponents[4]
            messagePart = windowsComponents[5]
        } else {
            filePart = String(components[0])
            linePart = components[1]
            columnPart = components[2]
            severityPart = components[3]
            messagePart = components[4]
        }

        guard let lineNumber = Int(linePart.trimmingCharacters(in: .whitespaces)),
            let columnNumber = Int(columnPart.trimmingCharacters(in: .whitespaces))
        else {
            return nil
        }

        let severityString = severityPart.trimmingCharacters(in: .whitespaces)
        guard let severity = Severity(rawValue: severityString) else { return nil }

        return CompilerDiagnostic(
            file: filePart,
            line: lineNumber,
            column: columnNumber,
            severity: severity,
            message: messagePart.trimmingCharacters(in: .whitespaces)
        )
    }
}
