import Foundation
import Testing

@testable import ScoreAuth
@testable import ScoreStorage

@Test func tokenGeneratesUniqueValues() {
    let a = Token.make()
    let b = Token.make()
    #expect(a != b)
    #expect(!a.value.isEmpty)
    #expect(!b.value.isEmpty)
}

@Test func tokenGeneratesExpectedLength() {
    let token = Token.make(byteCount: 16)
    #expect(!token.value.isEmpty)
    let longToken = Token.make(byteCount: 64)
    #expect(longToken.value.count > token.value.count)
}

@Test func tokenIsURLSafe() {
    for _ in 0..<10 {
        let token = Token.make()
        #expect(!token.value.contains("+"))
        #expect(!token.value.contains("/"))
        #expect(!token.value.contains("="))
    }
}

@Test func csrfTokenGeneratesUniqueValues() {
    let a = CSRFToken.make()
    let b = CSRFToken.make()
    #expect(a != b)
    #expect(!a.value.isEmpty)
}

@Test func csrfTokenConstantTimeEqualMatching() {
    let token = CSRFToken.make()
    let same = CSRFToken(value: token.value)
    #expect(CSRFToken.constantTimeEqual(token, same))
}

@Test func csrfTokenConstantTimeEqualMismatch() {
    let a = CSRFToken.make()
    let b = CSRFToken.make()
    #expect(!CSRFToken.constantTimeEqual(a, b))
}

@Test func csrfTokenEqualityUsesConstantTime() {
    let a = CSRFToken.make()
    let b = CSRFToken(value: a.value)
    #expect(a == b)

    let c = CSRFToken.make()
    #expect(a != c)
}

@Test func csrfTokenConstantTimeEqualDifferentLengths() {
    let short = CSRFToken(value: "abc")
    let long = CSRFToken(value: "abcdef")
    #expect(!CSRFToken.constantTimeEqual(short, long))
}

@Test func sessionDetectsExpiry() {
    let now = Date()
    let active = Session(
        id: "s1",
        userID: "u1",
        token: Token.make(),
        createdAt: now,
        expiresAt: now.addingTimeInterval(3600)
    )
    #expect(!active.isExpired)

    let expired = Session(
        id: "s2",
        userID: "u1",
        token: Token.make(),
        createdAt: now.addingTimeInterval(-7200),
        expiresAt: now.addingTimeInterval(-3600)
    )
    #expect(expired.isExpired)
}

@Test func magicLinkDetectsExpiry() {
    let now = Date()
    let active = MagicLink(
        token: Token.make(),
        email: "user@example.com",
        createdAt: now,
        expiresAt: now.addingTimeInterval(600)
    )
    #expect(!active.isExpired)

    let expired = MagicLink(
        token: Token.make(),
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

    let fetched = try await store.session(for: session.token)
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

@Test func sessionStoreValidateThrowsSessionNotFound() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let fakeToken = Token.make()
    await #expect {
        try await store.validate(token: fakeToken)
    } throws: { error in
        guard let authError = error as? AuthError,
            case .sessionNotFound = authError
        else { return false }
        return true
    }
}

@Test func sessionStoreDelete() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = SessionStore(storage: storage, config: config)

    let session = try await store.create(userID: "user_99")
    try await store.delete(token: session.token)
    let fetched = try await store.session(for: session.token)
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

    await #expect {
        try await store.validate(tokenValue: link.token.value)
    } throws: { error in
        guard let authError = error as? AuthError,
            case .tokenExpired = authError
        else { return false }
        return true
    }
}

@Test func magicLinkStoreThrowsForInvalidToken() async throws {
    let storage = InMemoryStore()
    let config = AuthConfig()
    let store = MagicLinkStore(storage: storage, config: config)

    await #expect {
        try await store.validate(tokenValue: "nonexistent")
    } throws: { error in
        guard let authError = error as? AuthError,
            case .tokenExpired = authError
        else { return false }
        return true
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
