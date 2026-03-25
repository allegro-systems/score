import Foundation
import Testing

@testable import ScoreRuntime

@Suite("MultipartParser")
struct FileUploadTests {

    @Test("Extracts boundary from content type")
    func extractsBoundary() {
        let contentType = "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
        let boundary = MultipartParser.extractBoundary(from: contentType)
        #expect(boundary == "----WebKitFormBoundary7MA4YWxkTrZu0gW")
    }

    @Test("Returns nil for non-multipart content type")
    func nilForNonMultipart() {
        let boundary = MultipartParser.extractBoundary(from: "application/json")
        #expect(boundary == nil)
    }

    @Test("Parses file uploads")
    func parsesFiles() {
        let boundary = "boundary123"
        let body = "--boundary123\r\nContent-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\nContent-Type: text/plain\r\n\r\nfile content\r\n--boundary123--\r\n"
        let result = MultipartParser.parse(data: Data(body.utf8), boundary: boundary)
        #expect(result.files["file"]?.filename == "test.txt")
        #expect(result.files["file"]?.contentType == "text/plain")
        #expect(String(data: result.files["file"]?.data ?? Data(), encoding: .utf8) == "file content")
    }

    @Test("Handles empty body gracefully")
    func handlesEmptyBody() {
        let result = MultipartParser.parse(data: Data(), boundary: "boundary123")
        #expect(result.files.isEmpty)
        #expect(result.fields.isEmpty)
    }
}
