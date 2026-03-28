import Foundation
import os

/// A protocol for persistent session storage.
public protocol SessionStore: Sendable {
    /// Retrieves a session by its identifier, or `nil` if not found or expired.
    func get(sessionID id: String) async throws -> Session?
    /// Persists a session.
    func save(_ session: Session) async throws
    /// Removes the session with the given identifier.
    func delete(sessionID id: String) async throws
    /// Removes all sessions belonging to the given user.
    func deleteAllForUser(_ userId: String) async throws
}

/// An in-memory session store for development and testing.
public final class MemorySessionStore: SessionStore, Sendable {

    private let sessions = OSAllocatedUnfairLock<[String: Session]>(initialState: [:])

    public init() {}

    public func get(sessionID id: String) async throws -> Session? {
        sessions.withLock { sessions in
            guard let session = sessions[id] else { return nil }
            if session.isExpired {
                sessions.removeValue(forKey: id)
                return nil
            }
            return session
        }
    }

    public func save(_ session: Session) async throws {
        sessions.withLock { store in
            store[session.id] = session
            // Sweep expired sessions on write to prevent unbounded growth
            if store.count > 100 {
                store = store.filter { !$0.value.isExpired }
            }
        }
    }

    public func delete(sessionID id: String) async throws {
        sessions.withLock { _ = $0.removeValue(forKey: id) }
    }

    public func deleteAllForUser(_ userId: String) async throws {
        sessions.withLock { sessions in
            sessions = sessions.filter { $0.value.userId != userId }
        }
    }
}
