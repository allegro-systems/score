import Crypto
import Foundation

/// Configuration for an OAuth2/OIDC provider.
///
/// `OAuthConfig` describes the endpoints and credentials needed to
/// perform an authorization code flow with PKCE.
///
/// ### Example
///
/// ```swift
/// let config = OAuthConfig.github(
///     clientID: "...",
///     clientSecret: "...",
///     redirectURI: "https://myapp.com/callback"
/// )
/// ```
public struct OAuthConfig: Sendable {

    /// The OAuth2 authorization endpoint URL.
    public let authorizeURL: String

    /// The OAuth2 token endpoint URL.
    public let tokenURL: String

    /// The OIDC userinfo endpoint URL, if available.
    public let userInfoURL: String?

    /// The OAuth2 client identifier.
    public let clientID: String

    /// The OAuth2 client secret.
    public let clientSecret: String

    /// The redirect URI registered with the provider.
    public let redirectURI: String

    /// The default scopes to request.
    public let scopes: [String]

    /// Creates an OAuth configuration.
    ///
    /// - Parameters:
    ///   - authorizeURL: The authorization endpoint.
    ///   - tokenURL: The token endpoint.
    ///   - userInfoURL: The userinfo endpoint.
    ///   - clientID: The client identifier.
    ///   - clientSecret: The client secret.
    ///   - redirectURI: The redirect URI.
    ///   - scopes: The requested scopes.
    public init(
        authorizeURL: String,
        tokenURL: String,
        userInfoURL: String? = nil,
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        scopes: [String] = []
    ) {
        self.authorizeURL = authorizeURL
        self.tokenURL = tokenURL
        self.userInfoURL = userInfoURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
    }

    /// Creates a GitHub OAuth configuration.
    ///
    /// - Parameters:
    ///   - clientID: The GitHub OAuth app client ID.
    ///   - clientSecret: The GitHub OAuth app client secret.
    ///   - redirectURI: The redirect URI.
    ///   - scopes: The requested scopes. Defaults to `["read:user", "user:email"]`.
    /// - Returns: A configured ``OAuthConfig``.
    public static func github(
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        scopes: [String] = ["read:user", "user:email"]
    ) -> OAuthConfig {
        OAuthConfig(
            authorizeURL: "https://github.com/login/oauth/authorize",
            tokenURL: "https://github.com/login/oauth/access_token",
            userInfoURL: "https://api.github.com/user",
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes
        )
    }

    /// Creates a Google OAuth/OIDC configuration.
    ///
    /// - Parameters:
    ///   - clientID: The Google OAuth client ID.
    ///   - clientSecret: The Google OAuth client secret.
    ///   - redirectURI: The redirect URI.
    ///   - scopes: The requested scopes. Defaults to `["openid", "email", "profile"]`.
    /// - Returns: A configured ``OAuthConfig``.
    public static func google(
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        scopes: [String] = ["openid", "email", "profile"]
    ) -> OAuthConfig {
        OAuthConfig(
            authorizeURL: "https://accounts.google.com/o/oauth2/v2/auth",
            tokenURL: "https://oauth2.googleapis.com/token",
            userInfoURL: "https://openidconnect.googleapis.com/v1/userinfo",
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes
        )
    }

    /// Creates an Apple Sign In configuration.
    ///
    /// - Parameters:
    ///   - clientID: The Apple Services ID.
    ///   - clientSecret: The generated client secret JWT.
    ///   - redirectURI: The redirect URI.
    ///   - scopes: The requested scopes. Defaults to `["name", "email"]`.
    /// - Returns: A configured ``OAuthConfig``.
    public static func apple(
        clientID: String,
        clientSecret: String,
        redirectURI: String,
        scopes: [String] = ["name", "email"]
    ) -> OAuthConfig {
        OAuthConfig(
            authorizeURL: "https://appleid.apple.com/auth/authorize",
            tokenURL: "https://appleid.apple.com/auth/token",
            userInfoURL: nil,
            clientID: clientID,
            clientSecret: clientSecret,
            redirectURI: redirectURI,
            scopes: scopes
        )
    }
}

/// An OAuth2 provider that handles authorization code flow with PKCE.
///
/// `OAuthProvider` generates authorization URLs, exchanges authorization
/// codes for tokens, and fetches user information from the provider.
///
/// ### Example
///
/// ```swift
/// let provider = OAuthProvider(config: .github(clientID: "...", clientSecret: "...", redirectURI: "..."))
/// let (url, state, verifier) = provider.authorizationURL()
/// // Redirect user to url, then handle callback:
/// let tokens = try await provider.exchangeCode("auth_code", codeVerifier: verifier)
/// ```
public struct OAuthProvider: Sendable {

    private let config: OAuthConfig

    /// Creates an OAuth provider with the given configuration.
    ///
    /// - Parameter config: The OAuth configuration.
    public init(config: OAuthConfig) {
        self.config = config
    }

    /// Generates an authorization URL with PKCE parameters.
    ///
    /// - Returns: A tuple of the authorization URL, the state parameter for
    ///   CSRF protection, and the PKCE code verifier to use when exchanging
    ///   the authorization code.
    public func authorizationURL() -> (url: String, state: String, codeVerifier: String) {
        let state = generateRandomString(length: 32)
        let codeVerifier = generateRandomString(length: 64)
        let codeChallenge = computeCodeChallenge(codeVerifier)

        var components = URLComponents(string: config.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]

        return (url: components.url!.absoluteString, state: state, codeVerifier: codeVerifier)
    }

    /// Exchanges an authorization code for access and refresh tokens.
    ///
    /// - Parameters:
    ///   - code: The authorization code from the callback.
    ///   - codeVerifier: The PKCE code verifier from ``authorizationURL()``.
    /// - Returns: The token response.
    public func exchangeCode(
        _ code: String,
        codeVerifier: String
    ) async throws -> OAuthTokenResponse {
        let url = URL(string: config.tokenURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = [
            "grant_type=authorization_code",
            "code=\(urlEncode(code))",
            "redirect_uri=\(urlEncode(config.redirectURI))",
            "client_id=\(urlEncode(config.clientID))",
            "client_secret=\(urlEncode(config.clientSecret))",
            "code_verifier=\(urlEncode(codeVerifier))",
        ].joined(separator: "&")

        request.httpBody = Data(body.utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OAuthTokenResponse.self, from: data)
    }

    /// Fetches user information using an access token.
    ///
    /// - Parameter accessToken: The OAuth access token.
    /// - Returns: The user info as a dictionary.
    public func fetchUserInfo(accessToken: String) async throws -> [String: Any] {
        guard let userInfoURL = config.userInfoURL else {
            throw OAuthError.userInfoNotSupported
        }

        let url = URL(string: userInfoURL)!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OAuthError.invalidResponse
        }
        return json
    }

    private func generateRandomString(length: Int) -> String {
        let key = SymmetricKey(size: .init(bitCount: length * 8))
        return key.withUnsafeBytes { Data($0) }.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(length)
            .description
    }

    private func computeCodeChallenge(_ verifier: String) -> String {
        let hash = SHA256.hash(data: Data(verifier.utf8))
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}

/// The response from an OAuth2 token exchange.
public struct OAuthTokenResponse: Sendable, Codable {

    /// The access token.
    public let accessToken: String

    /// The token type (typically "Bearer").
    public let tokenType: String?

    /// The refresh token, if provided.
    public let refreshToken: String?

    /// The token expiry in seconds, if provided.
    public let expiresIn: Int?

    /// The granted scopes.
    public let scope: String?

    /// The OIDC ID token, if provided.
    public let idToken: String?
}

/// Errors from OAuth operations.
public enum OAuthError: Error, Sendable {

    /// The provider does not support user info queries.
    case userInfoNotSupported

    /// The response from the provider was not in the expected format.
    case invalidResponse

    /// The state parameter did not match.
    case stateMismatch

    /// The authorization code exchange failed.
    case tokenExchangeFailed(String)
}
