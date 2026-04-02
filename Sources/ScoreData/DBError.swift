/// Errors thrown by `DBStore` and its backends.
public enum DBError: Error, Sendable {
    case tableNotRegistered(String)
    case recordNotFound(table: String, id: String)
    case serializationFailed(String)
    case unknownColumn(table: String, column: String)
}
