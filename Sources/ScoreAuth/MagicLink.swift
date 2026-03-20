import Foundation
import ScoreCore
import os

/// Configuration for magic link authentication.
public struct MagicLinkConfiguration: Sendable {

    /// Token expiration in seconds (default: 10 minutes).
    public let tokenExpiration: TimeInterval

    /// The base URL for magic link verification.
    public let baseURL: String

    /// The verification path.
    public let verifyPath: String

    public init(
        tokenExpiration: TimeInterval = 600,
        baseURL: String = "http://localhost:8080",
        verifyPath: String = "/auth/verify"
    ) {
        self.tokenExpiration = tokenExpiration
        self.baseURL = baseURL
        self.verifyPath = verifyPath
    }
}

/// A pending magic link token.
public struct MagicLinkToken: Sendable, Equatable {

    /// The token string.
    public let token: String

    /// The email address the token was sent to.
    public let email: String

    /// When the token expires.
    public let expiresAt: Date

    public init(token: String, email: String, expiresAt: Date) {
        self.token = token
        self.email = email
        self.expiresAt = expiresAt
    }

    /// Whether the token has expired.
    public var isExpired: Bool { Date() > expiresAt }
}

/// A protocol for sending magic link emails.
public protocol MagicLinkSender: Sendable {
    /// Delivers a magic link to the given email address.
    func send(to email: String, link: String) async throws
}

/// A magic link sender that logs links to stdout (for development).
public struct ConsoleMagicLinkSender: MagicLinkSender {

    public init() {}

    public func send(to email: String, link: String) async throws {
        print("[MagicLink] \(email): \(link)")
    }
}

/// Manages magic link token generation and verification.
public final class MagicLinkManager: Sendable {

    private let configuration: MagicLinkConfiguration
    private let sender: any MagicLinkSender
    private let pendingTokens = OSAllocatedUnfairLock<[String: MagicLinkToken]>(initialState: [:])

    public init(
        configuration: MagicLinkConfiguration = MagicLinkConfiguration(),
        sender: any MagicLinkSender = ConsoleMagicLinkSender()
    ) {
        self.configuration = configuration
        self.sender = sender
    }

    /// Generates a magic link and sends it to the given email.
    @discardableResult
    public func send(to email: String) async throws -> String {
        let token = CryptoRandom.hexToken()
        let magicToken = MagicLinkToken(
            token: token,
            email: email,
            expiresAt: Date().addingTimeInterval(configuration.tokenExpiration)
        )

        pendingTokens.withLock { tokens in
            // Lazy cleanup of expired tokens
            tokens = tokens.filter { !$0.value.isExpired }
            tokens[token] = magicToken
        }

        let link = "\(configuration.baseURL)\(configuration.verifyPath)?token=\(token)"
        try await sender.send(to: email, link: link)

        return token
    }

    /// Verifies a magic link token and returns the associated email.
    ///
    /// The token is consumed on successful verification (single use).
    public func verify(token: String) -> String? {
        pendingTokens.withLock { tokens in
            guard let magicToken = tokens.removeValue(forKey: token) else { return nil }
            guard !magicToken.isExpired else { return nil }
            return magicToken.email
        }
    }
}
