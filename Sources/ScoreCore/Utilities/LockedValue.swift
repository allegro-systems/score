import Foundation

/// A thread-safe value wrapper using `NSLock`.
///
/// Provides mutex-like semantics for protecting mutable state across
/// concurrency boundaries. All access is serialized through `withLock`.
///
/// ### Example
///
/// ```swift
/// let counter = LockedValue(0)
/// counter.withLock { value in value += 1 }
/// let current = counter.withLock { value in value }
/// ```
public final class LockedValue<Value: Sendable>: @unchecked Sendable {

    private var value: Value
    private let lock = NSLock()

    /// Creates a locked value with the given initial value.
    public init(_ value: Value) {
        self.value = value
    }

    /// Accesses the value under the lock.
    @discardableResult
    public func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
