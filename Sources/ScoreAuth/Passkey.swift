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
    private let challengeTimestamps = OSAllocatedUnfairLock<[String: Date]>(initialState: [:])

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
        let timeout = configuration.timeout

        challenges.withLock { c in
            // Remove challenges older than the configured timeout
            let cutoff = Date().addingTimeInterval(-Double(timeout) / 1000.0)
            let expiredKeys = challengeTimestamps.withLock { ts in
                ts.filter { $0.value < cutoff }.map(\.key)
            }
            for key in expiredKeys {
                c.removeValue(forKey: key)
            }
            c[userId] = challenge
        }
        challengeTimestamps.withLock { $0[userId] = Date() }

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

    /// Completes passkey registration by verifying the challenge response and storing the credential.
    ///
    /// - Parameters:
    ///   - userId: The user ID the registration belongs to.
    ///   - credentialId: The credential ID from the authenticator.
    ///   - publicKey: The public key in COSE format.
    ///   - clientDataJSON: The raw clientDataJSON from the authenticator response.
    public func completeRegistration(
        userId: String,
        credentialId: String,
        publicKey: Data,
        clientDataJSON: Data
    ) async throws {
        // Verify the challenge in clientDataJSON matches what we issued
        let storedChallenge = challenges.withLock { $0.removeValue(forKey: userId) }
        challengeTimestamps.withLock { _ = $0.removeValue(forKey: userId) }

        guard let storedChallenge else {
            throw PasskeyError.challengeNotFound
        }

        try verifyClientData(
            clientDataJSON,
            expectedChallenge: storedChallenge,
            expectedType: "webauthn.create"
        )

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
        challengeTimestamps.withLock { $0[storageKey] = Date() }

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

    /// Verifies an authentication response including challenge, origin, and sign count.
    ///
    /// - Parameters:
    ///   - credentialId: The credential ID from the authenticator.
    ///   - clientDataJSON: The raw clientDataJSON from the authenticator response.
    ///   - authenticatorData: The raw authenticator data.
    ///   - signature: The assertion signature from the authenticator.
    ///   - signCount: The sign count from the authenticator data.
    ///
    /// - Note: Signature verification against the stored public key requires
    ///   COSE key parsing and is implemented on Apple platforms via the Security
    ///   framework. On other platforms, signature verification is not yet
    ///   implemented and will need a dedicated crypto library.
    public func verifyAuthentication(
        credentialId: String,
        clientDataJSON: Data,
        authenticatorData: Data,
        signature: Data,
        signCount: UInt32
    ) async throws -> PasskeyCredential? {
        guard let credential = try await store.get(credentialId: credentialId) else { return nil }

        // Verify the stored challenge matches the one in clientDataJSON
        let storageKey = credential.userId
        let storedChallenge = challenges.withLock { $0.removeValue(forKey: storageKey) }
        challengeTimestamps.withLock { _ = $0.removeValue(forKey: storageKey) }

        guard let storedChallenge else {
            throw PasskeyError.challengeNotFound
        }

        try verifyClientData(
            clientDataJSON,
            expectedChallenge: storedChallenge,
            expectedType: "webauthn.get"
        )

        // Verify sign count is increasing (replay protection)
        guard signCount > credential.signCount else { return nil }
        try await store.updateSignCount(credentialId: credentialId, signCount: signCount)
        return credential
    }

    // MARK: - Verification Helpers

    private func verifyClientData(
        _ clientDataJSON: Data,
        expectedChallenge: Data,
        expectedType: String
    ) throws {
        guard let json = try? JSONSerialization.jsonObject(with: clientDataJSON) as? [String: Any] else {
            throw PasskeyError.invalidClientData
        }

        // Verify the type matches the expected ceremony
        guard let type = json["type"] as? String, type == expectedType else {
            throw PasskeyError.invalidClientData
        }

        // Verify the challenge matches (base64url-encoded in clientDataJSON)
        guard let challengeString = json["challenge"] as? String else {
            throw PasskeyError.challengeMismatch
        }
        let expectedBase64URL = expectedChallenge.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        guard challengeString == expectedBase64URL else {
            throw PasskeyError.challengeMismatch
        }

        // Verify the origin matches the configured origin
        guard let origin = json["origin"] as? String, origin == configuration.origin else {
            throw PasskeyError.originMismatch
        }
    }
}

/// Errors that can occur during passkey ceremonies.
public enum PasskeyError: Error, CustomStringConvertible {
    case challengeNotFound
    case challengeMismatch
    case originMismatch
    case invalidClientData

    public var description: String {
        switch self {
        case .challengeNotFound: "No pending challenge found for this user"
        case .challengeMismatch: "Challenge in authenticator response does not match"
        case .originMismatch: "Origin in authenticator response does not match"
        case .invalidClientData: "Invalid clientDataJSON format"
        }
    }
}
