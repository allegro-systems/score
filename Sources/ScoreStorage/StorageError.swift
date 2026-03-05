import Foundation

/// An error raised by the Score storage layer.
///
/// `StorageError` covers the failure modes common to all storage backends,
/// from missing keys to serialisation problems and transaction conflicts.
public enum StorageError: Error, Sendable {

    /// The requested key does not exist in the store.
    ///
    /// - Parameter key: The key that was not found.
    case keyNotFound(Key)

    /// A transaction could not commit because of a conflicting concurrent write.
    case transactionConflict

    /// A value could not be encoded for storage.
    ///
    /// - Parameter message: A description of what went wrong during encoding.
    case encodingFailed(String)

    /// A stored value could not be decoded into the requested type.
    ///
    /// - Parameter message: A description of what went wrong during decoding.
    case decodingFailed(String)
}
