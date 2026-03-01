import Foundation

/// Generates v3 source maps that map emitted JavaScript back to Swift source files.
///
/// `SourceMap` produces a JSON payload conforming to the
/// [Source Map Revision 3](https://sourcemaps.info/spec.html) specification.
/// Each mapping connects a generated JS line/column to an original Swift
/// file path and line/column.
///
/// ### Example
///
/// ```swift
/// var builder = SourceMap.Builder(file: "page-script.js")
/// builder.addMapping(
///     generatedLine: 1, generatedColumn: 0,
///     source: "Sources/App/HomePage.swift", sourceLine: 12, sourceColumn: 4,
///     name: "count"
/// )
/// let json = builder.build()
/// ```
public enum SourceMap: Sendable {

    /// A single source mapping entry.
    public struct Mapping: Sendable, Equatable {
        /// Zero-based line in the generated JS.
        public let generatedLine: Int
        /// Zero-based column in the generated JS.
        public let generatedColumn: Int
        /// Index into the sources array.
        public let sourceIndex: Int
        /// Zero-based line in the original source.
        public let sourceLine: Int
        /// Zero-based column in the original source.
        public let sourceColumn: Int
        /// Optional index into the names array.
        public let nameIndex: Int?
    }

    /// Incrementally builds a v3 source map.
    public struct Builder: Sendable {
        /// The name of the generated file.
        public let file: String

        private var sources: [String] = []
        private var sourceIndices: [String: Int] = [:]
        private var names: [String] = []
        private var nameIndices: [String: Int] = [:]
        private var mappings: [Mapping] = []

        /// Creates a builder for the given generated file.
        public init(file: String) {
            self.file = file
        }

        /// Adds a mapping from a generated JS position to an original source position.
        public mutating func addMapping(
            generatedLine: Int,
            generatedColumn: Int,
            source: String,
            sourceLine: Int,
            sourceColumn: Int,
            name: String? = nil
        ) {
            let sourceIdx: Int
            if let existing = sourceIndices[source] {
                sourceIdx = existing
            } else {
                sourceIdx = sources.count
                sources.append(source)
                sourceIndices[source] = sourceIdx
            }

            var nameIdx: Int?
            if let n = name {
                if let existing = nameIndices[n] {
                    nameIdx = existing
                } else {
                    nameIdx = names.count
                    names.append(n)
                    nameIndices[n] = nameIdx
                }
            }

            mappings.append(
                Mapping(
                    generatedLine: generatedLine,
                    generatedColumn: generatedColumn,
                    sourceIndex: sourceIdx,
                    sourceLine: sourceLine,
                    sourceColumn: sourceColumn,
                    nameIndex: nameIdx
                )
            )
        }

        /// Builds the v3 source map JSON string.
        public func build() -> String {
            let encodedMappings = encodeMappings()
            let sourcesJSON = sources.map { "\"\(escapeJSON($0))\"" }.joined(separator: ",")
            let namesJSON = names.map { "\"\(escapeJSON($0))\"" }
                .joined(separator: ",")

            return "{\"version\":3,\"file\":\"\(escapeJSON(file))\","
                + "\"sources\":[\(sourcesJSON)],"
                + "\"names\":[\(namesJSON)],"
                + "\"mappings\":\"\(encodedMappings)\"}"
        }

        private func encodeMappings() -> String {
            guard !mappings.isEmpty else { return "" }

            let sorted = mappings.sorted {
                ($0.generatedLine, $0.generatedColumn) < ($1.generatedLine, $1.generatedColumn)
            }

            var result = ""
            var previousGeneratedLine = 0
            var previousGeneratedColumn = 0
            var previousSourceIndex = 0
            var previousSourceLine = 0
            var previousSourceColumn = 0
            var previousNameIndex = 0
            var firstSegmentOnLine = true

            for mapping in sorted {
                // Emit semicolons for lines between previous and current.
                while previousGeneratedLine < mapping.generatedLine {
                    result.append(";")
                    previousGeneratedLine += 1
                    previousGeneratedColumn = 0
                    firstSegmentOnLine = true
                }

                if !firstSegmentOnLine {
                    result.append(",")
                }
                firstSegmentOnLine = false

                // Field 1: generated column (relative).
                result.append(vlqEncode(mapping.generatedColumn - previousGeneratedColumn))
                previousGeneratedColumn = mapping.generatedColumn

                // Field 2: source index (relative).
                result.append(vlqEncode(mapping.sourceIndex - previousSourceIndex))
                previousSourceIndex = mapping.sourceIndex

                // Field 3: source line (relative).
                result.append(vlqEncode(mapping.sourceLine - previousSourceLine))
                previousSourceLine = mapping.sourceLine

                // Field 4: source column (relative).
                result.append(vlqEncode(mapping.sourceColumn - previousSourceColumn))
                previousSourceColumn = mapping.sourceColumn

                // Field 5: name index (relative), if present.
                if let nameIdx = mapping.nameIndex {
                    result.append(vlqEncode(nameIdx - previousNameIndex))
                    previousNameIndex = nameIdx
                }
            }

            return result
        }
    }

    // MARK: - VLQ Encoding

    private static let base64Chars: [Character] = Array(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    )

    /// Encodes a signed integer as a Base64-VLQ string.
    static func vlqEncode(_ value: Int) -> String {
        var vlq = value < 0 ? ((-value) << 1) | 1 : value << 1
        var result = ""
        repeat {
            var digit = vlq & 0x1F
            vlq >>= 5
            if vlq > 0 {
                digit |= 0x20  // continuation bit
            }
            result.append(base64Chars[digit])
        } while vlq > 0
        return result
    }

    private static func escapeJSON(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// Make the free function accessible from Builder.
private func vlqEncode(_ value: Int) -> String {
    SourceMap.vlqEncode(value)
}

private func escapeJSON(_ string: String) -> String {
    string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}
