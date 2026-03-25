import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A `MagicLinkSender` that delivers magic link emails via the Resend API.
///
/// Requires a Resend API key and a verified sender address.
///
/// ```swift
/// let sender = ResendMagicLinkSender(
///     apiKey: "re_...",
///     from: "Libretto <noreply@allegro.systems>"
/// )
/// ```
///
/// Set up at [resend.com](https://resend.com) — free tier supports
/// 100 emails/day and 3,000/month.
public struct ResendMagicLinkSender: MagicLinkSender {

    private let apiKey: String
    private let from: String
    private let subject: String
    private let productName: String

    /// Creates a Resend-backed magic link sender.
    ///
    /// - Parameters:
    ///   - apiKey: Your Resend API key (starts with `re_`).
    ///   - from: The verified sender address, e.g. `"App <noreply@example.com>"`.
    ///   - subject: The email subject line.
    ///   - productName: The product name shown in the email body.
    public init(
        apiKey: String,
        from: String = "Allegro <noreply@allegro.systems>",
        subject: String = "Your sign-in link",
        productName: String = "Allegro"
    ) {
        self.apiKey = apiKey
        self.from = from
        self.subject = subject
        self.productName = productName
    }

    public func send(to email: String, link: String) async throws {
        guard !apiKey.isEmpty else {
            // Fallback to console in development when no API key is set
            print("[MagicLink] No RESEND_API_KEY set — printing link instead:")
            print("[MagicLink] \(email): \(link)")
            return
        }

        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "from": from,
            "to": [email],
            "subject": subject,
            "html": emailHTML(link: link, email: email),
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
            !(200..<300).contains(httpResponse.statusCode)
        {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw MagicLinkEmailError.sendFailed(
                statusCode: httpResponse.statusCode,
                body: responseBody
            )
        }
    }

    private func emailHTML(link: String, email: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head><meta charset="utf-8"></head>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; \
        background: #0f0e0c; color: #e8e0d0; padding: 40px 20px;">
          <div style="max-width: 480px; margin: 0 auto;">
            <h1 style="font-family: Georgia, serif; font-size: 24px; font-weight: 300; \
        margin-bottom: 24px; color: #e8e0d0;">\(productName)</h1>
            <p style="font-size: 15px; line-height: 1.6; color: #a09888; margin-bottom: 24px;">
              Click the button below to sign in to your account. This link expires in 10 minutes.
            </p>
            <a href="\(link)" style="display: inline-block; padding: 14px 32px; \
        background: #c8a96e; color: #0f0e0c; text-decoration: none; font-size: 14px; \
        font-weight: 600; border-radius: 6px;">Sign In</a>
            <p style="font-size: 12px; color: #5a5448; margin-top: 32px; line-height: 1.5;">
              If you didn\u{2019}t request this email, you can safely ignore it.<br>
              This link was sent to \(email).
            </p>
            <hr style="border: none; border-top: 1px solid #2e2a22; margin: 24px 0;">
            <p style="font-size: 11px; color: #3d3830;">
              \(productName) \u{2014} part of the Allegro ecosystem
            </p>
          </div>
        </body>
        </html>
        """
    }
}

/// Errors specific to magic link email delivery.
public enum MagicLinkEmailError: Error, CustomStringConvertible {
    case sendFailed(statusCode: Int, body: String)

    public var description: String {
        switch self {
        case .sendFailed(let statusCode, let body):
            "Magic link email failed (HTTP \(statusCode)): \(body)"
        }
    }
}
