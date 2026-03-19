/// A node that renders a translated string for the current locale.
///
/// `Localized` looks up a translation key in the active
/// ``LocalizationContext`` and renders the resulting text. When no
/// localization context is set (e.g. when the app has no i18n configured),
/// it falls back to the provided default text or the key itself.
///
/// ### Example
///
/// ```swift
/// struct HomePage: Page {
///     static let path = "/"
///
///     var body: some Node {
///         Heading(.one) { Localized("home.title") }
///         Paragraph { Localized("home.subtitle") }
///     }
/// }
/// ```
///
/// You can also provide a default value for when no translation is found:
///
/// ```swift
/// Localized("home.cta", default: "Get Started")
/// ```
///
/// For convenience, use the free ``t(_:default:)`` function which returns
/// a `String` directly:
///
/// ```swift
/// SiteButton(title: t("home.cta", default: "Get Started"), link: "/docs")
/// ```
public struct Localized: Node, Sendable {

    /// The translation key to look up.
    public let key: String

    /// An optional default string used when no translation is found.
    public let defaultValue: String?

    /// Creates a localized text node.
    ///
    /// - Parameters:
    ///   - key: The translation key.
    ///   - defaultValue: An optional fallback string. When `nil`, the key itself
    ///     is used as fallback.
    public init(_ key: String, default defaultValue: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    /// The resolved text content for this node.
    ///
    /// `Localized` is a primitive node — its body is `Never`. The resolved
    /// text is accessed via this property by the HTML renderer.
    public var resolvedText: String {
        if let context = LocalizationContext.current {
            let translated = context.translate(key)
            if translated != key {
                return translated
            }
        }
        return defaultValue ?? key
    }

    public var body: Never { fatalError() }
}

/// Resolves a translation key for the current locale.
///
/// This is a convenience function that returns a `String` directly,
/// suitable for passing to components that accept `String` parameters.
///
/// When no ``LocalizationContext`` is active, returns the `default` value
/// if provided, or the key itself.
///
/// ### Example
///
/// ```swift
/// SiteButton(title: t("nav.get_started", default: "Get Started"), link: "/docs")
/// FeatureCard(
///     icon: "zap",
///     title: t("features.swift_first.title"),
///     description: t("features.swift_first.description")
/// )
/// ```
///
/// - Parameters:
///   - key: The translation key.
///   - defaultValue: An optional fallback string.
/// - Returns: The translated string.
public func t(_ key: String, default defaultValue: String? = nil) -> String {
    if let context = LocalizationContext.current {
        let translated = context.translate(key)
        if translated != key {
            return translated
        }
    }
    return defaultValue ?? key
}
