/// Errors that can occur during KV store operations.
public enum KVError: Error, Sendable {

    /// An atomic commit failed due to a version conflict.
    case commitConflict(key: KVKey)

    /// The key was not found.
    case notFound(key: KVKey)

    /// A serialization error occurred.
    case serializationFailed(String)
}
