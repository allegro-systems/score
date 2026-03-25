import Foundation

/// A parsed file from a multipart form-data upload.
public struct UploadedFile: Sendable {

    /// The form field name.
    public let fieldName: String

    /// The original filename from the client.
    public let filename: String

    /// The MIME content type.
    public let contentType: String

    /// The file data.
    public let data: Data

    public init(fieldName: String, filename: String, contentType: String, data: Data) {
        self.fieldName = fieldName
        self.filename = filename
        self.contentType = contentType
        self.data = data
    }
}

/// Parsed multipart form data containing files and text fields.
public struct MultipartFormData: Sendable {

    /// Uploaded files keyed by field name.
    public let files: [String: UploadedFile]

    /// Text fields keyed by field name.
    public let fields: [String: String]

    public init(files: [String: UploadedFile] = [:], fields: [String: String] = [:]) {
        self.files = files
        self.fields = fields
    }
}

/// Parses multipart form-data from request bodies.
public struct MultipartParser: Sendable {

    /// Parses a multipart form-data body using the given boundary.
    public static func parse(data: Data, boundary: String) -> MultipartFormData {
        let boundaryData = Data("--\(boundary)".utf8)
        let crlf = Data("\r\n".utf8)
        let doubleCRLF = Data("\r\n\r\n".utf8)

        var files: [String: UploadedFile] = [:]
        var fields: [String: String] = [:]

        let parts = splitParts(data: data, boundary: boundaryData)

        for part in parts {
            guard let headerEnd = part.range(of: doubleCRLF) else { continue }
            let headerData = part[part.startIndex..<headerEnd.lowerBound]
            let bodyData = part[headerEnd.upperBound...]

            guard let headerString = String(data: headerData, encoding: .utf8) else { continue }
            let headers = parsePartHeaders(headerString)

            guard let disposition = headers["content-disposition"] else { continue }
            guard let name = extractParameter("name", from: disposition) else { continue }

            if let filename = extractParameter("filename", from: disposition) {
                let contentType = headers["content-type"] ?? "application/octet-stream"
                var fileData = Data(bodyData)
                if fileData.count >= crlf.count && fileData.suffix(crlf.count) == crlf {
                    fileData = fileData.dropLast(crlf.count)
                }
                files[name] = UploadedFile(
                    fieldName: name,
                    filename: filename,
                    contentType: contentType,
                    data: fileData
                )
            } else {
                var fieldData = Data(bodyData)
                if fieldData.count >= crlf.count && fieldData.suffix(crlf.count) == crlf {
                    fieldData = fieldData.dropLast(crlf.count)
                }
                fields[name] = String(data: fieldData, encoding: .utf8) ?? ""
            }
        }

        return MultipartFormData(files: files, fields: fields)
    }

    /// Extracts the boundary from a Content-Type header.
    public static func extractBoundary(from contentType: String) -> String? {
        guard contentType.contains("multipart/form-data") else { return nil }
        return extractParameter("boundary", from: contentType)
    }

    private static func splitParts(data: Data, boundary: Data) -> [Data] {
        var parts: [Data] = []
        var searchStart = data.startIndex
        let crlf = Data("\r\n".utf8)

        guard let firstRange = data.range(of: boundary, in: searchStart..<data.endIndex) else {
            return parts
        }
        searchStart = firstRange.upperBound

        if searchStart < data.endIndex && data[searchStart...].starts(with: crlf) {
            searchStart = data.index(searchStart, offsetBy: crlf.count)
        }

        while searchStart < data.endIndex {
            guard let nextRange = data.range(of: boundary, in: searchStart..<data.endIndex) else {
                break
            }

            let partData = Data(data[searchStart..<nextRange.lowerBound])
            if !partData.isEmpty {
                parts.append(partData)
            }

            searchStart = nextRange.upperBound

            let closingMarker = Data("--".utf8)
            if searchStart < data.endIndex && data[searchStart...].starts(with: closingMarker) {
                break
            }

            if searchStart < data.endIndex && data[searchStart...].starts(with: crlf) {
                searchStart = data.index(searchStart, offsetBy: crlf.count)
            }
        }

        return parts
    }

    private static func parsePartHeaders(_ headerString: String) -> [String: String] {
        var headers: [String: String] = [:]
        for line in headerString.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }
        return headers
    }

    private static func extractParameter(_ name: String, from header: String) -> String? {
        // Scan header segments (separated by ;) for name=value or name="value"
        for segment in header.split(separator: ";") {
            let trimmed = segment.trimmingCharacters(in: .whitespaces)
            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<equalsIndex].trimmingCharacters(in: .whitespaces)
            guard key == name else { continue }
            var val = trimmed[trimmed.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
            if val.hasPrefix("\"") && val.hasSuffix("\"") && val.count >= 2 {
                val = String(val.dropFirst().dropLast())
            }
            return val
        }
        return nil
    }
}
