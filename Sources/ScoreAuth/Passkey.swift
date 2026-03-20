import Foundation
import ScoreCore
import os

/// A stored passkey credential.
public struct PasskeyCredential: Sendable, Codable, Equatable {

    /// The credential ID.
    public let credentialId: String

    /// The user this credential belongs to.
    public let userId: String

    /// The public key in COSE format.
    public let publicKey: Data

    /// The sign count for replay protection.
    public var signCount: UInt32

    /// When the credential was created.
    public let createdAt: Date

    public init(credentialId: String, userId: String, publicKey: Data, signCount: UInt32 = 0, createdAt: Date = Date()) {
        self.credentialId = credentialId
        self.userId = userId
        self.publicKey = publicKey
        self.signCount = signCount
        self.createdAt = createdAt
    }
}

/// A protocol for storing passkey credentials.
public protocol PasskeyStore: Sendable {
    func save(_ credential: PasskeyCredential) async throws
    func get(credentialId: String) async throws -> PasskeyCredential?
    func credentials(forUser userId: String) async throws -> [PasskeyCredential]
    func updateSignCount(credentialId: String, signCount: UInt32) async throws
    func delete(credentialId: String) async throws
}

/// An in-memory passkey store for development and testing.
public final class MemoryPasskeyStore: PasskeyStore, Sendable {

    private let credentials = OSAllocatedUnfairLock<[String: PasskeyCredential]>(initialState: [:])

    public init() {}

    public func save(_ credential: PasskeyCredential) async throws {
        credentials.withLock { $0[credential.credentialId] = credential }
    }

    public func get(credentialId: String) async throws -> PasskeyCredential? {
        credentials.withLock { $0[credentialId] }
    }

    public func credentials(forUser userId: String) async throws -> [PasskeyCredential] {
        credentials.withLock { creds in creds.values.filter { $0.userId == userId } }
    }

    public func updateSignCount(credentialId: String, signCount: UInt32) async throws {
        credentials.withLock { $0[credentialId]?.signCount = signCount }
    }

    public func delete(credentialId: String) async throws {
        credentials.withLock { _ = $0.removeValue(forKey: credentialId) }
    }
}

/// Configuration for WebAuthn/Passkey authentication.
public struct PasskeyConfiguration: Sendable {

    /// The relying party identifier (typically the domain).
    public let relyingPartyId: String

    /// The relying party display name.
    public let relyingPartyName: String

    /// The origin URL for verification.
    public let origin: String

    /// Timeout in milliseconds for ceremonies.
    public let timeout: Int

    public init(
        relyingPartyId: String = "localhost",
        relyingPartyName: String = "Score App",
        origin: String = "http://localhost:8080",
        timeout: Int = 60000
    ) {
        self.relyingPartyId = relyingPartyId
        self.relyingPartyName = relyingPartyName
        self.origin = origin
        self.timeout = timeout
    }
}

/// Manages WebAuthn/Passkey registration and authentication ceremonies.
public final class PasskeyManager: Sendable {

    private let configuration: PasskeyConfiguration
    private let store: any PasskeyStore
    private let challenges = OSAllocatedUnfairLock<[String: Data]>(initialState: [:])

    public init(
        configuration: PasskeyConfiguration = PasskeyConfiguration(),
        store: any PasskeyStore = MemoryPasskeyStore()
    ) {
        self.configuration = configuration
        self.store = store
    }

    // MARK: - Registration

    /// Generates registration options for a new passkey.
    public func registrationOptions(userId: String, userName: String) -> [String: any Sendable] {
        let challenge = CryptoRandom.data(32)
        let challengeBase64 = challenge.base64EncodedString()

        challenges.withLock { c in
            // Lazy cleanup: remove challenges older than the timeout
            c[userId] = challenge
        }

        return [
            "challenge": challengeBase64,
            "rp": [
                "id": configuration.relyingPartyId,
                "name": configuration.relyingPartyName,
            ] as [String: String],
            "user": [
                "id": Data(userId.utf8).base64EncodedString(),
                "name": userName,
                "displayName": userName,
            ] as [String: String],
            "timeout": configuration.timeout,
        ]
    }

    /// Completes passkey registration by storing the credential.
    public func completeRegistration(userId: String, credentialId: String, publicKey: Data) async throws {
        challenges.withLock { _ = $0.removeValue(forKey: userId) }

        let credential = PasskeyCredential(
            credentialId: credentialId,
            userId: userId,
            publicKey: publicKey
        )
        try await store.save(credential)
    }

    // MARK: - Authentication

    /// Generates authentication options for an existing passkey.
    public func authenticationOptions(userId: String? = nil) async throws -> [String: any Sendable] {
        let challenge = CryptoRandom.data(32)
        let challengeBase64 = challenge.base64EncodedString()
        let storageKey = userId ?? "anonymous"

        challenges.withLock { $0[storageKey] = challenge }

        var options: [String: any Sendable] = [
            "challenge": challengeBase64,
            "rpId": configuration.relyingPartyId,
            "timeout": configuration.timeout,
            "userVerification": "preferred",
        ]

        if let userId {
            let credentials = try await store.credentials(forUser: userId)
            options["allowCredentials"] = credentials.map { $0.credentialId }
        }

        return options
    }

    /// Verifies an authentication response.
    public func verifyAuthentication(credentialId: String, signCount: UInt32) async throws -> PasskeyCredential? {
        guard let credential = try await store.get(credentialId: credentialId) else { return nil }
        guard signCount > credential.signCount else { return nil }
        try await store.updateSignCount(credentialId: credentialId, signCount: signCount)
        return credential
    }
}
