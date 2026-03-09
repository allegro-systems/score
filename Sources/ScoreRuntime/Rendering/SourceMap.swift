/// Generates source maps (V3) for mapping emitted JS back to Swift sources.
public struct SourceMap {

    private init() {}

    /// A builder for constructing source map JSON.
    public struct Builder {
        private let file: String
        private var sources: [String] = []
        private var sourceIndices: [String: Int] = [:]
        private var names: [String] = []
        private var nameIndices: [String: Int] = [:]
        private var mappingSegments: [[String]] = []  // per generated line

        /// Creates a builder for the given generated file name.
        public init(file: String) {
            self.file = file
        }

        /// Adds a mapping from generated position to source position.
        public mutating func addMapping(
            generatedLine: Int,
            generatedColumn: Int,
            source: String,
            sourceLine: Int,
            sourceColumn: Int,
            name: String? = nil
        ) {
            let sourceIndex = ensureSource(source)

            // Ensure we have enough lines
            while mappingSegments.count <= generatedLine {
                mappingSegments.append([])
            }

            var segment = ""
            segment.append(SourceMap.vlqEncode(generatedColumn))
            segment.append(SourceMap.vlqEncode(sourceIndex))
            segment.append(SourceMap.vlqEncode(sourceLine))
            segment.append(SourceMap.vlqEncode(sourceColumn))

            if let name = name {
                let nameIndex = ensureName(name)
                segment.append(SourceMap.vlqEncode(nameIndex))
            }

            mappingSegments[generatedLine].append(segment)
        }

        /// Builds the source map JSON string.
        public func build() -> String {
            let mappings =
                mappingSegments
                .map { $0.joined(separator: ",") }
                .joined(separator: ";")

            let escapedFile = file.replacingOccurrences(of: "\"", with: "\\\"")
            let escapedSources = sources.map { "\"\($0.replacingOccurrences(of: "\"", with: "\\\""))\"" }
            let escapedNames = names.map { "\"\($0.replacingOccurrences(of: "\"", with: "\\\""))\"" }

            return """
                {"version":3,"file":"\(escapedFile)","sources":[\(escapedSources.joined(separator: ","))],"names":[\(escapedNames.joined(separator: ","))],"mappings":"\(mappings)"}
                """
        }

        private mutating func ensureSource(_ source: String) -> Int {
            if let index = sourceIndices[source] { return index }
            let index = sources.count
            sources.append(source)
            sourceIndices[source] = index
            return index
        }

        private mutating func ensureName(_ name: String) -> Int {
            if let index = nameIndices[name] { return index }
            let index = names.count
            names.append(name)
            nameIndices[name] = index
            return index
        }
    }

    // MARK: - VLQ Encoding

    private static let base64Chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

    /// Encodes a single integer as a VLQ base64 string.
    public static func vlqEncode(_ value: Int) -> String {
        var vlq = value < 0 ? ((-value) << 1) | 1 : value << 1
        var result = ""
        repeat {
            var digit = vlq & 0x1F
            vlq >>= 5
            if vlq > 0 { digit |= 0x20 }
            result.append(base64Chars[digit])
        } while vlq > 0
        return result
    }
}
