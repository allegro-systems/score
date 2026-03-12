/// The HTTP method used to submit form data to the server.
///
/// `HTTPMethod` maps directly to the `method` attribute of the HTML `<form>`
/// element and determines how the browser encodes and transmits form data.
///
/// ### Example
///
/// ```swift
/// Form(action: "/login", method: .post) {
///     Input(type: .email, name: "email")
///     Input(type: .password, name: "password")
///     Button(type: .submit) { Text("Sign In") }
/// }
/// ```
public enum HTTPMethod: String, Sendable {

    /// Appends form data to the URL as query parameters.
    ///
    /// Suitable for searches and other idempotent requests where the data does
    /// not need to be hidden from the URL bar.
    case get

    /// Sends form data in the HTTP request body.
    ///
    /// Use for actions that create or mutate server-side state, or when the
    /// payload contains sensitive information such as passwords.
    case post

    /// Sends form data via a dialog submission.
    ///
    /// Only valid for forms nested inside a `<dialog>` element. When submitted,
    /// the dialog closes and its `returnValue` is set to the button's value.
    case dialog
}

/// The MIME type used to encode form data before it is sent to the server.
///
/// `FormEncoding` maps directly to the `enctype` attribute of the HTML
/// `<form>` element and is only relevant when the form's `method` is `.post`.
///
/// ### Example
///
/// ```swift
/// Form(action: "/upload", method: .post, encoding: .multipart) {
///     Input(type: .file, name: "avatar")
///     Button(type: .submit) { Text("Upload") }
/// }
/// ```
public enum FormEncoding: String, Sendable {

    /// Encodes form data as URL-encoded key-value pairs.
    ///
    /// This is the default encoding for POST forms. Special characters in
    /// field values are percent-encoded. Not suitable for file uploads.
    case urlEncoded = "application/x-www-form-urlencoded"

    /// Encodes form data as multipart sections, each with its own headers.
    ///
    /// Required when the form contains file inputs (`Input(type: .file)`),
    /// because binary file data cannot be percent-encoded efficiently.
    case multipart = "multipart/form-data"

    /// Encodes form data as plain text with minimal encoding.
    ///
    /// Spaces are converted to `+` symbols but no other encoding is applied.
    /// Useful for debugging, but not recommended for production use as it is
    /// not reliably parseable by all servers.
    case plainText = "text/plain"
}

/// A node that renders an HTML form element for collecting and submitting user input.
///
/// `Form` renders as the HTML `<form>` element and groups one or more input
/// controls together with a submission target. When submitted, the browser
/// serialises the values of all named controls inside the form and sends them
/// to `action` using `method`.
///
/// An optional `id` allows `Button` nodes elsewhere in the document to
/// associate themselves with this form via their `form` property, even when
/// they are not DOM descendants of the form.
///
/// ### Example
///
/// ```swift
/// Form(action: "/signup", method: .post) {
///     Label(for: "email-input") { Text("Email") }
///     Input(type: .email, name: "email", id: "email-input", required: true)
///     Button(type: .submit) { Text("Create Account") }
/// }
///
/// // File upload form with multipart encoding
/// Form(action: "/upload", method: .post, encoding: .multipart) {
///     Input(type: .file, name: "document")
///     Button(type: .submit) { Text("Upload") }
/// }
/// ```
///
/// - Note: Always choose the most specific `HTTPMethod` for the intended
///   server-side operation. Prefer `.post` over `.get` for sensitive data.
public struct Form<Content: Node>: Node, SourceLocatable {

    /// The URL to which the form data is sent upon submission.
    ///
    /// Corresponds to the `action` attribute on the HTML `<form>` element.
    public let action: String

    /// The HTTP method used to transmit the form data.
    ///
    /// Corresponds to the `method` attribute on the HTML `<form>` element.
    public let method: HTTPMethod

    /// The MIME type used to encode the form data before submission.
    ///
    /// When `nil`, the browser defaults to `.urlEncoded` for POST requests.
    /// Corresponds to the `enctype` attribute on the HTML `<form>` element.
    public let encoding: FormEncoding?

    /// A unique identifier for this form element.
    ///
    /// When set, `Button` nodes anywhere in the document can reference this
    /// form via their own `form` property without being nested inside it.
    /// Corresponds to the `id` attribute on the HTML `<form>` element.
    public let id: String?

    /// The child nodes that constitute the form's controls and layout.
    public let content: Content

    public let sourceLocation: SourceLocation

    /// Creates a form with the given submission target and child content.
    public init(
        action: String,
        method: HTTPMethod,
        encoding: FormEncoding? = nil,
        id: String? = nil,
        file: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column,
        @NodeBuilder content: () -> Content
    ) {
        self.action = action
        self.method = method
        self.encoding = encoding
        self.id = id
        self.sourceLocation = SourceLocation(fileID: file, filePath: filePath, line: line, column: column)
        self.content = content()
    }

    /// This node is rendered directly by the Score runtime and does not have a
    /// composable body.
    public var body: Never { fatalError() }
}
