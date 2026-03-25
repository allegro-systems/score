/// Configuration for application-level internationalization.
///
/// `Localization` holds the set of supported locales, the default locale,
/// and a translation table mapping `(locale, key)` pairs to translated
/// strings.
///
/// ### Example
///
/// ```swift
/// var localization: Localization? {
///     Localization(
///         defaultLocale: "en",
///         supportedLocales: ["en", "es", "de"],
///         translations: [
///             "en": [
///                 "nav.about": "About",
///                 "nav.blog": "Blog",
///             ],
///             "es": [
///                 "nav.about": "Acerca de",
///                 "nav.blog": "Blog",
///             ],
///         ]
///     )
/// }
/// ```
public struct Localization: Sendable {

    /// The default locale used when no locale is specified or when a
    /// translation key is missing for the requested locale.
    public let defaultLocale: SiteLocale

    /// The set of locales this application supports.
    ///
    /// During static site generation, pages are emitted once per supported
    /// locale. The default locale's pages are emitted at the root path
    /// (e.g. `/about`), while other locales are emitted under a prefix
    /// (e.g. `/es/about`).
    public let supportedLocales: [SiteLocale]

    /// The translation table: `translations[locale][key] = translated string`.
    public let translations: [String: [String: String]]

    /// Creates a localization configuration.
    ///
    /// - Parameters:
    ///   - defaultLocale: The fallback locale.
    ///   - supportedLocales: All locales the application supports.
    ///   - translations: A nested dictionary of `[localeIdentifier: [key: value]]`.
    public init(
        defaultLocale: SiteLocale,
        supportedLocales: [SiteLocale],
        translations: [String: [String: String]]
    ) {
        self.defaultLocale = defaultLocale
        self.supportedLocales = supportedLocales
        self.translations = translations
    }

    /// Creates a localization configuration from a parsed String Catalog.
    ///
    /// This initializer extracts the source language, supported locales, and
    /// all translation tables from an Xcode `.xcstrings` file, making it easy
    /// to share translations between a Score web project and a SwiftUI app.
    ///
    /// ### Example
    ///
    /// ```swift
    /// let catalog = try StringCatalog.load(from: "Localizable.xcstrings")
    ///
    /// var localization: Localization? {
    ///     Localization(catalog: catalog)
    /// }
    /// ```
    ///
    /// - Parameter catalog: A parsed ``StringCatalog``.
    public init(catalog: StringCatalog) {
        self.defaultLocale = SiteLocale(catalog.sourceLanguage)
        self.supportedLocales = catalog.locales.map { SiteLocale($0) }
        var translations: [String: [String: String]] = [:]
        for locale in catalog.locales {
            translations[locale] = catalog.translations(for: locale)
        }
        self.translations = translations
    }

    /// Looks up a translation for the given key and locale.
    ///
    /// Falls back to the default locale if the key is not found in the
    /// requested locale. Returns the key itself if no translation exists
    /// in any locale.
    ///
    /// - Parameters:
    ///   - key: The translation key.
    ///   - locale: The desired locale.
    /// - Returns: The translated string, or the key if no translation is found.
    public func translate(_ key: String, locale: SiteLocale) -> String {
        if let value = translations[locale.identifier]?[key] {
            return value
        }
        if let value = translations[defaultLocale.identifier]?[key] {
            return value
        }
        return key
    }
}
