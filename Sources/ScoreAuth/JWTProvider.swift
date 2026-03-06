import Crypto
import Foundation

/// A JSON Web Token provider for signing and verifying JWTs.
///
/// `JWTProvider` supports HS256 and HS384 signing algorithms with configurable
/// expiry and refresh token flows.
///
/// ### Example
///
/// ```swift
/// let provider = JWTProvider(secret: "my-secret-key")
/// let token = try provider.sign(claims: ["sub": "user123"])
/// let verified = try provider.verify(token)
/// ```
public struct JWTProvider: Sendable {

    /// The signing algorithm.
    public enum Algorithm: String, Sendable {
        case hs256 = "HS256"
        case hs384 = "HS384"
    }

    private let secret: Data
    private let algorithm: Algorithm
    private let issuer: String?
    private let defaultExpiry: Duration

    /// Creates a JWT provider.
    ///
    /// - Parameters:
    ///   - secret: The HMAC secret key string.
    ///   - algorithm: The signing algorithm. Defaults to `.hs256`.
    ///   - issuer: An optional issuer claim. Defaults to `nil`.
    ///   - defaultExpiry: The default token expiry. Defaults to 1 hour.
    public init(
        secret: String,
        algorithm: Algorithm = .hs256,
        issuer: String? = nil,
        defaultExpiry: Duration = .seconds(3600)
    ) {
        self.secret = Data(secret.utf8)
        self.algorithm = algorithm
        self.issuer = issuer
        self.defaultExpiry = defaultExpiry
    }

    /// Signs a set of claims into a JWT string.
    ///
    /// - Parameters:
    ///   - claims: The claims dictionary. Values must be JSON-serializable strings.
    ///   - expiry: Override the default expiry duration.
    /// - Returns: The signed JWT string.
    public func sign(
        claims: [String: String],
        expiry: Duration? = nil
    ) throws -> String {
        let now = Date()
        let expiryDuration = expiry ?? defaultExpiry
        let (seconds, _) = expiryDuration.components
        let exp = now.addingTimeInterval(TimeInterval(seconds))

        var payload: [String: Any] = [:]
        for (key, value) in claims {
            payload[key] = value
        }
        payload["iat"] = Int(now.timeIntervalSince1970)
        payload["exp"] = Int(exp.timeIntervalSince1970)
        if let issuer {
            payload["iss"] = issuer
        }

        let header: [String: Any] = [
            "alg": algorithm.rawValue,
            "typ": "JWT",
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        let headerEncoded = base64URLEncode(headerData)
        let payloadEncoded = base64URLEncode(payloadData)

        let signingInput = "\(headerEncoded).\(payloadEncoded)"
        let signature = computeHMAC(Data(signingInput.utf8))
        let signatureEncoded = base64URLEncode(signature)

        return "\(signingInput).\(signatureEncoded)"
    }

    /// Verifies a JWT string and returns the claims.
    ///
    /// - Parameter token: The JWT string to verify.
    /// - Returns: The verified claims as a ``JWTClaims`` value.
    public func verify(_ token: String) throws -> JWTClaims {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw JWTError.malformedToken
        }

        let signingInput = "\(parts[0]).\(parts[1])"
        let expectedSignature = computeHMAC(Data(signingInput.utf8))
        let expectedEncoded = base64URLEncode(expectedSignature)

        guard constantTimeCompare(String(parts[2]), expectedEncoded) else {
            throw JWTError.invalidSignature
        }

        guard let payloadData = base64URLDecode(String(parts[1])) else {
            throw JWTError.malformedToken
        }

        guard let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw JWTError.malformedToken
        }

        if let exp = payload["exp"] as? Int {
            let expiryDate = Date(timeIntervalSince1970: TimeInterval(exp))
            guard Date() < expiryDate else {
                throw JWTError.expired
            }
        }

        if let issuer, let tokenIssuer = payload["iss"] as? String {
            guard tokenIssuer == issuer else {
                throw JWTError.invalidIssuer
            }
        }

        var claims: [String: String] = [:]
        for (key, value) in payload {
            if let stringValue = value as? String {
                claims[key] = stringValue
            } else {
                claims[key] = "\(value)"
            }
        }

        return JWTClaims(values: claims)
    }

    /// Generates a signed refresh token.
    ///
    /// - Parameters:
    ///   - subject: The subject identifier.
    ///   - expiry: Refresh token expiry. Defaults to 30 days.
    /// - Returns: The signed refresh token JWT.
    public func generateRefreshToken(
        subject: String,
        expiry: Duration = .seconds(2_592_000)
    ) throws -> String {
        try sign(claims: ["sub": subject, "type": "refresh"], expiry: expiry)
    }

    private func computeHMAC(_ data: Data) -> Data {
        let key = SymmetricKey(data: secret)
        switch algorithm {
        case .hs256:
            let mac = HMAC<SHA256>.authenticationCode(for: data, using: key)
            return Data(mac)
        case .hs384:
            let mac = HMAC<SHA384>.authenticationCode(for: data, using: key)
            return Data(mac)
        }
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64.append(contentsOf: repeatElement("=", count: padding))
        return Data(base64Encoded: base64)
    }

    private func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        guard aBytes.count == bBytes.count else { return false }
        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        return result == 0
    }
}

/// Verified JWT claims.
public struct JWTClaims: Sendable {

    /// The raw claims dictionary.
    public let values: [String: String]

    /// Returns the subject claim (`sub`), or `nil`.
    public var subject: String? { values["sub"] }

    /// Returns the issuer claim (`iss`), or `nil`.
    public var issuer: String? { values["iss"] }

    /// Returns the value for a custom claim key, or `nil`.
    ///
    /// - Parameter key: The claim key.
    /// - Returns: The claim value.
    public subscript(key: String) -> String? { values[key] }
}

/// Errors from JWT operations.
public enum JWTError: Error, Sendable {

    /// The token string is malformed.
    case malformedToken

    /// The signature does not match.
    case invalidSignature

    /// The token has expired.
    case expired

    /// The issuer does not match the expected value.
    case invalidIssuer
}
