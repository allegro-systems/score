import Foundation
import Testing

@testable import ScoreAuth
@testable import ScoreStorage

@Test func tokenGeneratesUniqueValues() {
    let a = Token.generate()
    let b = Token.generate()
    #expect(a != b)
    #expect(!a.value.isEmpty)
    #expect(!b.value.isEmpty)
}

@Test func tokenGeneratesExpectedLength() {
    let token = Token.generate(byteCount: 16)
    #expect(!token.value.isEmpty)
    let longToken = Token.generate(byteCount: 64)
    #expect(longToken.value.count > token.value.count)
}

@Test func tokenIsURLSafe() {
    for _ in 0..<10 {
        let token = Token.generate()
        #expect(!token.value.contains("+"))
        #expect(!token.value.contains("/"))
        #expect(!token.value.contains("="))
    }
}

@Test func csrfTokenGeneratesUniqueValues() {
    let a = CSRFToken.generate()
    let b = CSRFToken.generate()
    #expect(a != b)
    #expect(!a.value.isEmpty)
}

@Test func sessionDetectsExpiry() {
    let now = Date()
    let active = Session(
        id: "s1",
        userID: "u1",
        token: Token.generate(),
        createdAt: now,
        expiresAt: now.addingTimeInterval(3600)
    )
    #expect(!active.isExpired)

    let expired = Session(
        id: "s2",
        userID: "u1",
        token: Token.generate(),
        createdAt: now.addingTimeInterval(-7200),
        expiresAt: now.addingTimeInterval(-3600)
    )
    #expect(expired.isExpired)
}

@Test func magicLinkDetectsExpiry() {
    let now = Date()
    let active = MagicLink(
        token: Token.generate(),
        email: "user@example.com",
        createdAt: now,
        expiresAt: now.addingTimeInterval(600)
    )
    #expect(!active.isExpired)

    let expired = MagicLink(
        token: Token.generate(),
        email: "user@example.com",
        createdAt: now.addingTimeInterval(-1200),
        expiresAt: now.addingTimeInterval(-600)
    )
    #expect(expired.isExpired)
}

@Test func passkeyChalllengeDetectsExpiry() {
    let now = Date()
    let active = PasskeyChallenge(
        challenge: "abc",
        relyingPartyID: "example.com",
        userID: "u1",
        createdAt: now,
        expiresAt: now.addingTimeInterval(300)
    )
    #expect(!active.isExpired)

    let expired = PasskeyChallenge(
        challenge: "def",
        relyingPartyID: "example.com",
        userID: "u1",
        createdAt: now.addingTimeInterval(-600),
        expiresAt: now.addingTimeInterval(-300)
    )
    #expect(expired.isExpired)
}

@Test func authConfigDefaults() {
    let config = AuthConfig()
    #expect(config.sessionTTL == .seconds(86400))
    #expect(config.magicLinkTTL == .seconds(600))
    #expect(config.csrfTTL == .seconds(3600))
    #expect(config.rateLimit.attempts == 5)
    #expect(config.rateLimit.window == .seconds(900))
    #expect(config.cookieName == "score_session")
    #expect(config.cookieSecure == true)
    #expect(config.cookieSameSite == .lax)
}

@Test func authConfigCustomValues() {
    let config = AuthConfig(
        sessionTTL: .seconds(7200),
        magicLinkTTL: .seconds(300),
        cookieName: "my_session",
        cookieSecure: false,
        cookieSameSite: .strict
    )
    #expect(config.sessionTTL == .seconds(7200))
    #expect(config.magicLinkTTL == .seconds(300))
    #expect(config.cookieName == "my_session")
    #expect(config.cookieSecure == false)
    #expect(config.cookieSameSite == .strict)
}

@Test func sameSitePolicyRawValues() {
    #expect(AuthConfig.SameSitePolicy.strict.rawValue == "Strict")
    #expect(AuthConfig.SameSitePolicy.lax.rawValue == "Lax")
    #expect(AuthConfig.SameSitePolicy.none.rawValue == "None")
}

@Test func emailConfigurationDefaults() {
    let email = EmailConfiguration()
    #expect(email.fromAddress == "noreply@localhost")
    #expect(email.fromName == "Score Auth")
    #expect(email.subjectPrefix == "")
}

@Test func sessionStoreCreateAndGet() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let session = try await store.create(userID: "user_42")
    #expect(session.userID == "user_42")
    #expect(!session.id.isEmpty)
    #expect(!session.token.value.isEmpty)
    #expect(!session.isExpired)

    let fetched = try await store.get(token: session.token)
    #expect(fetched != nil)
    #expect(fetched?.userID == "user_42")
    #expect(fetched?.id == session.id)
}

@Test func sessionStoreValidateReturnsSession() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let session = try await store.create(userID: "user_1")
    let validated = try await store.validate(token: session.token)
    #expect(validated.userID == "user_1")
}

@Test func sessionStoreValidateThrowsForMissingToken() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let fakeToken = Token.generate()
    await #expect(throws: AuthError.self) {
        try await store.validate(token: fakeToken)
    }
}

@Test func sessionStoreDelete() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let session = try await store.create(userID: "user_99")
    try await store.delete(token: session.token)
    let fetched = try await store.get(token: session.token)
    #expect(fetched == nil)
}

@Test func magicLinkStoreCreateAndValidate() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = MagicLinkStore(storage: storage, config: config)

    let link = try await store.create(email: "test@example.com")
    #expect(link.email == "test@example.com")
    #expect(!link.isExpired)

    let validated = try await store.validate(tokenValue: link.token.value)
    #expect(validated.email == "test@example.com")
}

@Test func magicLinkStoreDeletesAfterValidation() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = MagicLinkStore(storage: storage, config: config)

    let link = try await store.create(email: "test@example.com")
    _ = try await store.validate(tokenValue: link.token.value)

    await #expect(throws: AuthError.self) {
        try await store.validate(tokenValue: link.token.value)
    }
}

@Test func magicLinkStoreThrowsForInvalidToken() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = MagicLinkStore(storage: storage, config: config)

    await #expect(throws: AuthError.self) {
        try await store.validate(tokenValue: "nonexistent")
    }
}

@Test func sessionCodableRoundTrip() throws {
    let session = Session(
        id: "s1",
        userID: "u1",
        token: Token(value: "tok123"),
        createdAt: Date(timeIntervalSince1970: 1000),
        expiresAt: Date(timeIntervalSince1970: 2000)
    )
    let data = try JSONEncoder().encode(session)
    let decoded = try JSONDecoder().decode(Session.self, from: data)
    #expect(decoded.id == session.id)
    #expect(decoded.userID == session.userID)
    #expect(decoded.token == session.token)
}

@Test func magicLinkCodableRoundTrip() throws {
    let link = MagicLink(
        token: Token(value: "ml_tok"),
        email: "user@test.com",
        createdAt: Date(timeIntervalSince1970: 1000),
        expiresAt: Date(timeIntervalSince1970: 2000)
    )
    let data = try JSONEncoder().encode(link)
    let decoded = try JSONDecoder().decode(MagicLink.self, from: data)
    #expect(decoded.token == link.token)
    #expect(decoded.email == link.email)
}

@Test func passkeyCredentialStoresFields() {
    let cred = PasskeyCredential(
        id: "cred_1",
        userID: "user_1",
        publicKey: Data([0x01, 0x02, 0x03]),
        signCount: 42,
        createdAt: Date()
    )
    #expect(cred.id == "cred_1")
    #expect(cred.userID == "user_1")
    #expect(cred.signCount == 42)
    #expect(cred.publicKey.count == 3)
}

@Test func passkeyCredentialCodableRoundTrip() throws {
    let cred = PasskeyCredential(
        id: "cred_1",
        userID: "user_1",
        publicKey: Data([0x01, 0x02, 0x03]),
        signCount: 7,
        createdAt: Date(timeIntervalSince1970: 5000)
    )
    let data = try JSONEncoder().encode(cred)
    let decoded = try JSONDecoder().decode(PasskeyCredential.self, from: data)
    #expect(decoded.id == cred.id)
    #expect(decoded.publicKey == cred.publicKey)
    #expect(decoded.signCount == cred.signCount)
}
