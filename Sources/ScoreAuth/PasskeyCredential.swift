import Foundation

/// A stored passkey credential linked to a user account.
///
/// After a successful WebAuthn registration ceremony, the credential's
/// public key and metadata are persisted so that future authentication
/// ceremonies can verify assertion signatures.
public struct PasskeyCredential: Codable, Sendable {

    /// The unique credential identifier assigned by the authenticator.
    public let id: String

    /// The identifier of the user who owns this credential.
    public let userID: String

    /// The COSE-encoded public key from the authenticator.
    public let publicKey: Data

    /// The signature counter reported by the authenticator.
    public var signCount: UInt32

    /// The date and time when the credential was registered.
    public let createdAt: Date

    /// Creates a new passkey credential record.
    ///
    /// - Parameters:
    ///   - id: The authenticator-assigned credential identifier.
    ///   - userID: The owning user's identifier.
    ///   - publicKey: The COSE-encoded public key.
    ///   - signCount: The initial signature counter value.
    ///   - createdAt: Registration timestamp.
    public init(
        id: String,
        userID: String,
        publicKey: Data,
        signCount: UInt32,
        createdAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.publicKey = publicKey
        self.signCount = signCount
        self.createdAt = createdAt
    }
}
