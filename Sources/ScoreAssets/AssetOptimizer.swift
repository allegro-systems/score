import Foundation

#if canImport(zlib)
import zlib
#elseif canImport(CZlib)
import CZlib
#endif

/// Content encoding applied during optimization.
///
/// Represents the transfer encoding that was applied to an asset during
/// the optimization pass. The value corresponds to the HTTP
/// `Content-Encoding` header value (e.g. `"gzip"`).
public struct ContentEncoding: Sendable, Hashable {

    /// The encoding identifier suitable for use in HTTP headers.
    public let value: String

    /// Deflate content encoding (zlib format).
    public static let deflate = ContentEncoding(value: "deflate")
}

/// The result of an optimization pass on an asset.
///
/// `OptimizedAsset` captures both the (possibly compressed) data and
/// metadata about the optimization — original and final sizes, the
/// encoding applied, and derived convenience properties for logging
/// and diagnostics.
public struct OptimizedAsset: Sendable {

    /// The optimized (or original) asset data.
    public let data: Data

    /// The byte count of the asset before optimization.
    public let originalSize: Int

    /// The byte count of the asset after optimization.
    public let optimizedSize: Int

    /// The content encoding applied, or `nil` if the data is uncompressed.
    public let encoding: ContentEncoding?

    /// The number of bytes saved by optimization.
    ///
    /// A positive value indicates the optimized data is smaller than the
    /// original. A value of zero means no savings were achieved.
    public var savedBytes: Int {
        originalSize - optimizedSize
    }

    /// The ratio of optimized size to original size.
    ///
    /// A value of `1.0` means no compression occurred. A value of `0.5`
    /// means the data was compressed to half its original size. Returns
    /// `1.0` when the original size is zero to avoid division by zero.
    public var compressionRatio: Double {
        guard originalSize > 0 else { return 1.0 }
        return Double(optimizedSize) / Double(originalSize)
    }
}

/// Applies optimizations to asset data based on type.
///
/// `AssetOptimizer` inspects the ``AssetType`` to determine whether
/// compression is beneficial. Text-based assets (CSS, JS, HTML, etc.)
/// are compressed using zlib deflate. Binary assets that are already
/// compressed (PNG, JPEG, WOFF2, etc.) are returned unchanged.
///
/// If compression would increase the data size — as can happen with
/// very small files — the original data is returned instead.
public struct AssetOptimizer: Sendable {

    /// Creates an asset optimizer with default settings.
    public init() {}

    /// Compresses the given data using zlib deflate if the asset type is compressible.
    ///
    /// Returns the original data if the asset type is not compressible or if
    /// compression would increase the data size.
    ///
    /// - Parameters:
    ///   - data: The raw asset data to optimize.
    ///   - type: The detected asset type, used to decide whether compression
    ///     is appropriate.
    /// - Returns: An ``OptimizedAsset`` containing the result.
    public func optimize(_ data: Data, type: AssetType) -> OptimizedAsset {
        guard type.isCompressible, !data.isEmpty else {
            return OptimizedAsset(
                data: data,
                originalSize: data.count,
                optimizedSize: data.count,
                encoding: nil
            )
        }

        if let compressed = Self.deflateCompress(data),
            compressed.count < data.count
        {
            return OptimizedAsset(
                data: compressed,
                originalSize: data.count,
                optimizedSize: compressed.count,
                encoding: .deflate
            )
        }

        return OptimizedAsset(
            data: data,
            originalSize: data.count,
            optimizedSize: data.count,
            encoding: nil
        )
    }

    /// Compresses data using raw deflate (RFC 1951) via the zlib C library.
    public static func deflateCompress(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }

        var stream = z_stream()
        let initResult = deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            -15,
            8,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard initResult == Z_OK else { return nil }
        defer { deflateEnd(&stream) }

        let outputCapacity = deflateBound(&stream, UInt(data.count))
        var output = Data(count: Int(outputCapacity))

        let result: Int32 = data.withUnsafeBytes { inputPtr in
            output.withUnsafeMutableBytes { outputPtr in
                stream.next_in = UnsafeMutablePointer(
                    mutating: inputPtr.bindMemory(to: UInt8.self).baseAddress)
                stream.avail_in = uInt(data.count)
                stream.next_out = outputPtr.bindMemory(to: UInt8.self).baseAddress
                stream.avail_out = uInt(outputCapacity)
                return deflate(&stream, Z_FINISH)
            }
        }

        guard result == Z_STREAM_END else { return nil }
        output.count = Int(stream.total_out)
        return output
    }
}
