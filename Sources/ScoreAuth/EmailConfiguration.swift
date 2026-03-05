/// Configuration for sending authentication emails.
///
/// Controls the sender address, display name, and subject line prefix
/// used when delivering magic link emails to users.
///
/// ```swift
/// let email = EmailConfiguration(
///     fromAddress: "auth@example.com",
///     fromName: "My App"
/// )
/// ```
public struct EmailConfiguration: Sendable {

    /// The email address used as the sender.
    public var fromAddress: String

    /// The display name shown alongside the sender address.
    public var fromName: String

    /// A prefix prepended to all authentication email subject lines.
    public var subjectPrefix: String

    /// Creates a new email configuration.
    ///
    /// - Parameters:
    ///   - fromAddress: Sender email address. Defaults to `"noreply@localhost"`.
    ///   - fromName: Sender display name. Defaults to `"Score Auth"`.
    ///   - subjectPrefix: Subject prefix. Defaults to `""`.
    public init(
        fromAddress: String = "noreply@localhost",
        fromName: String = "Score Auth",
        subjectPrefix: String = ""
    ) {
        self.fromAddress = fromAddress
        self.fromName = fromName
        self.subjectPrefix = subjectPrefix
    }
}
