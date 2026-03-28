import Foundation
import ScoreAssets

extension HTTPMiddleware {

    /// Creates a middleware that compresses response bodies.
    ///
    /// Supports gzip and deflate encoding. Prefers gzip when the client
    /// advertises support for it. Only compresses responses larger than the
    /// minimum size threshold and whose content type is compressible.
    public static func compression(minimumSize: Int = 1024) -> HTTPMiddleware {
        HTTPMiddleware { request, next in
            var response = try await next(request)

            let acceptEncoding = request.headers["accept-encoding"] ?? request.headers["Accept-Encoding"] ?? ""
            guard response.body.count >= minimumSize else { return response }

            let contentType = response.headers["content-type"] ?? ""
            guard isCompressible(contentType) else { return response }

            // Prefer gzip over deflate
            if acceptEncoding.contains("gzip") {
                if let compressed = AssetOptimizer.gzipCompress(response.body),
                    compressed.count < response.body.count
                {
                    response.body = compressed
                    response.headers["content-encoding"] = "gzip"
                    response.headers["vary"] = "Accept-Encoding"
                    return response
                }
            }

            if acceptEncoding.contains("deflate") {
                if let compressed = AssetOptimizer.deflateCompress(response.body),
                    compressed.count < response.body.count
                {
                    response.body = compressed
                    response.headers["content-encoding"] = "deflate"
                    response.headers["vary"] = "Accept-Encoding"
                    return response
                }
            }

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
