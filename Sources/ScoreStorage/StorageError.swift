/// Errors thrown by ``Store`` operations.
public enum StorageError: Error, Sendable {

    /// The requested key was not found.
    case keyNotFound(Key)

    /// A transaction could not be committed due to a conflict.
    case transactionConflict
}
