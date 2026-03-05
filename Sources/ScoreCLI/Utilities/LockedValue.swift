import Foundation

/// A thread-safe value wrapper using `NSLock`.
///
/// Provides `Mutex`-like semantics for macOS 14+ where
/// `Synchronization.Mutex` is not available.
final class LockedValue<Value: Sendable>: @unchecked Sendable {

    private var value: Value
    private let lock = NSLock()

    /// Creates a locked value with the given initial value.
    init(_ value: Value) {
        self.value = value
    }

    /// Accesses the value under the lock.
    @discardableResult
    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
