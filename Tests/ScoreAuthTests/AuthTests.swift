import Foundation
import Testing

@testable import ScoreAuth

@Suite("MagicLink")
struct MagicLinkTests {

    @Test("Generates and verifies a magic link token")
    func generateAndVerify() async throws {
        let manager = MagicLinkManager()
        let token = try await manager.send(to: "test@example.com")
        let email = manager.verify(token: token)
        #expect(email == "test@example.com")
    }

    @Test("Token is single-use")
    func singleUse() async throws {
        let manager = MagicLinkManager()
        let token = try await manager.send(to: "test@example.com")
        _ = manager.verify(token: token)
        let secondVerify = manager.verify(token: token)
        #expect(secondVerify == nil)
    }

    @Test("Invalid token returns nil")
    func invalidToken() {
        let manager = MagicLinkManager()
        let email = manager.verify(token: "nonexistent")
        #expect(email == nil)
    }

    @Test("Expired token returns nil")
    func expiredToken() async throws {
        let config = MagicLinkConfiguration(tokenExpiration: -1)
        let manager = MagicLinkManager(configuration: config)
        let token = try await manager.send(to: "test@example.com")
        let email = manager.verify(token: token)
        #expect(email == nil)
    }
}

@Suite("Session")
struct SessionTests {

    @Test("Session store saves and retrieves")
    func storeBasic() async throws {
        let store = MemorySessionStore()
        let session = Session(userId: "user1")
        try await store.save(session)
        let retrieved = try await store.get(sessionID: session.id)
        #expect(retrieved?.userId == "user1")
    }

    @Test("Session store deletes")
    func storeDelete() async throws {
        let store = MemorySessionStore()
        let session = Session(userId: "user1")
        try await store.save(session)
        try await store.delete(sessionID: session.id)
        let retrieved = try await store.get(sessionID: session.id)
        #expect(retrieved == nil)
    }

    @Test("Expired sessions are not returned")
    func expiredSession() async throws {
        let store = MemorySessionStore()
        let session = Session(userId: "user1", expiresAt: Date().addingTimeInterval(-1))
        try await store.save(session)
        let retrieved = try await store.get(sessionID: session.id)
        #expect(retrieved == nil)
    }
}

@Suite("CSRF")
struct CSRFTests {

    @Test("Generates and validates token")
    func generateAndValidate() {
        let csrf = CSRFProtection()
        let token = csrf.generateToken()
        #expect(csrf.validate(token))
    }

    @Test("Token is single-use")
    func singleUse() {
        let csrf = CSRFProtection()
        let token = csrf.generateToken()
        _ = csrf.validate(token)
        #expect(!csrf.validate(token))
    }

    @Test("Invalid token fails")
    func invalidToken() {
        let csrf = CSRFProtection()
        #expect(!csrf.validate("fake"))
    }
}

@Suite("Passkey")
struct PasskeyTests {

    @Test("Registration options contain required fields")
    func registrationOptions() {
        let manager = PasskeyManager()
        let options = manager.registrationOptions(userId: "user1", userName: "Alice")
        #expect(options["challenge"] != nil)
    }

    @Test("Complete registration stores credential")
    func completeRegistration() async throws {
        let store = MemoryPasskeyStore()
        let manager = PasskeyManager(store: store)
        try await manager.completeRegistration(
            userId: "user1",
            credentialId: "cred1",
            publicKey: Data([1, 2, 3])
        )
        let credential = try await store.get(credentialId: "cred1")
        #expect(credential?.userId == "user1")
    }

    @Test("Passkey store CRUD operations")
    func storeCRUD() async throws {
        let store = MemoryPasskeyStore()
        let cred = PasskeyCredential(credentialId: "c1", userId: "u1", publicKey: Data([1]))
        try await store.save(cred)

        let fetched = try await store.get(credentialId: "c1")
        #expect(fetched?.userId == "u1")

        let userCreds = try await store.credentials(forUser: "u1")
        #expect(userCreds.count == 1)

        try await store.updateSignCount(credentialId: "c1", signCount: 5)
        let updated = try await store.get(credentialId: "c1")
        #expect(updated?.signCount == 5)

        try await store.delete(credentialId: "c1")
        let deleted = try await store.get(credentialId: "c1")
        #expect(deleted == nil)
    }

    @Test("Authentication verification checks sign count")
    func verifyAuthentication() async throws {
        let store = MemoryPasskeyStore()
        let manager = PasskeyManager(store: store)
        try await manager.completeRegistration(
            userId: "user1",
            credentialId: "cred1",
            publicKey: Data([1, 2, 3])
        )
        let result = try await manager.verifyAuthentication(credentialId: "cred1", signCount: 1)
        #expect(result != nil)
        let failed = try await manager.verifyAuthentication(credentialId: "cred1", signCount: 0)
        #expect(failed == nil)
    }
}
