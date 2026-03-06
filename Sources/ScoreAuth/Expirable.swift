import Foundation

/// A type that carries an expiration timestamp.
///
/// Conforming types gain a default ``isExpired`` implementation that
/// checks the current wall clock against ``expiresAt``.
protocol Expirable {
    var expiresAt: Date { get }
}

extension Expirable {
    /// Whether this value has passed its expiration time.
    var isExpired: Bool {
        Date() >= expiresAt
    }
}
