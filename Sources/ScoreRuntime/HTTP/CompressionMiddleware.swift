import Foundation
import ScoreAssets

extension HTTPMiddleware {

    /// Creates a middleware that compresses response bodies using deflate.
    ///
    /// Only compresses responses larger than the minimum size threshold and
    /// whose content type is compressible (text, JSON, CSS, JavaScript, SVG, XML).
    /// Compression is only applied when the client advertises `deflate` support.
    public static func compression(minimumSize: Int = 1024) -> HTTPMiddleware {
        HTTPMiddleware { request, next in
            var response = try await next(request)

            let acceptEncoding = request.headers["accept-encoding"] ?? request.headers["Accept-Encoding"] ?? ""
            guard acceptEncoding.contains("deflate") else { return response }
            guard response.body.count >= minimumSize else { return response }

            let contentType = response.headers["content-type"] ?? ""
            guard isCompressible(contentType) else { return response }

            guard let compressed = AssetOptimizer.deflateCompress(response.body) else { return response }
            guard compressed.count < response.body.count else { return response }

            response.body = compressed
            response.headers["content-encoding"] = "deflate"
            response.headers["vary"] = "Accept-Encoding"

            return response
        }
    }

    private static func isCompressible(_ contentType: String) -> Bool {
        let compressible = [
            "text/", "application/json", "application/javascript",
            "application/xml", "image/svg+xml",
        ]
        return compressible.contains(where: { contentType.contains($0) })
    }
}
