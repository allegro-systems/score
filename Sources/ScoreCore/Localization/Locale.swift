/// A locale identifier used for internationalization.
///
/// `SiteLocale` wraps an IETF BCP 47 language tag (e.g. `"en"`, `"es"`,
/// `"de"`) and is used throughout the i18n system to select translations
/// and set the `lang` attribute on rendered HTML documents.
///
/// ### Example
///
/// ```swift
/// let english = SiteLocale("en")
/// let spanish = SiteLocale("es")
/// ```
public struct SiteLocale: Sendable, Hashable, Equatable {

    /// The BCP 47 language tag (e.g. `"en"`, `"es"`, `"fr-CA"`).
    public let identifier: String

    /// Creates a locale from a language tag string.
    ///
    /// - Parameter identifier: A BCP 47 language tag.
    public init(_ identifier: String) {
        self.identifier = identifier
    }
}

extension SiteLocale: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.identifier = value
    }
}

extension SiteLocale: CustomStringConvertible {
    public var description: String { identifier }
}
