import Foundation

/// Machine-readable error output for tooling integrations.
///
/// When JSON mode is enabled, command failures emit this schema.
/// Compatible with Composer and other Score tooling consumers.
struct StructuredError: Codable, Sendable {
    let code: String
    let message: String
    let stage: String?
    let file: String?
    let line: Int?
    let column: Int?
    let details: [String]

    init(
        code: String,
        message: String,
        stage: String? = nil,
        file: String? = nil,
        line: Int? = nil,
        column: Int? = nil,
        details: [String] = []
    ) {
        self.code = code
        self.message = message
        self.stage = stage
        self.file = file
        self.line = line
        self.column = column
        self.details = details
    }

    /// Encodes this error as a JSON string.
    func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}
