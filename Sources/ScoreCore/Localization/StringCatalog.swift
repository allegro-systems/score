import Foundation

/// A parsed representation of an Xcode String Catalog (`.xcstrings`) file.
///
/// String Catalogs are the standard Apple localization format introduced in
/// Xcode 15. By supporting this format, Score applications can share a single
/// `.xcstrings` file between a Score web project and a SwiftUI app.
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
/// The `.xcstrings` file is a JSON document with this structure:
///
/// ```json
/// {
///   "sourceLanguage": "en",
///   "version": "1.0",
///   "strings": {
///     "nav.about": {
///       "localizations": {
///         "en": { "stringUnit": { "state": "translated", "value": "About" } },
///         "es": { "stringUnit": { "state": "translated", "value": "Acerca de" } }
///       }
///     }
///   }
/// }
/// ```
///
/// - SeeAlso: [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/Xcode/localizing-and-varying-text-with-a-string-catalog)
public struct StringCatalog: Sendable {

    /// The source (development) language for this catalog.
    public let sourceLanguage: String

    /// The format version of the catalog.
    public let version: String

    /// All string entries keyed by their translation key.
    public let strings: [String: StringEntry]

    /// A single localizable string entry in the catalog.
    public struct StringEntry: Sendable {

        /// An optional comment describing this string's usage context.
        public let comment: String?

        /// Translations keyed by locale identifier.
        public let localizations: [String: LocalizationValue]
    }

    /// A single locale's translation for a string entry.
    public struct LocalizationValue: Sendable {

        /// The translated string unit.
        public let stringUnit: StringUnit
    }

    /// The translated text and its state.
    public struct StringUnit: Sendable {

        /// The translation state (e.g. `"translated"`, `"new"`, `"needs_review"`).
        public let state: String

        /// The translated string value.
        public let value: String
    }

    // MARK: - Loading

    /// Loads and parses a `.xcstrings` file from disk.
    ///
    /// Resolves relative paths against the current working directory,
    /// matching the convention used by ``ContentLoader``.
    ///
    /// - Parameter path: Absolute or relative path to the `.xcstrings` file.
    /// - Returns: A parsed ``StringCatalog``.
    /// - Throws: If the file cannot be read or the JSON is malformed.
    public static func load(from path: String) throws -> StringCatalog {
        let resolvedPath: String
        if path.hasPrefix("/") {
            resolvedPath = path
        } else {
            resolvedPath = FileManager.default.currentDirectoryPath + "/" + path
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: resolvedPath))
        let raw = try JSONDecoder().decode(RawCatalog.self, from: data)
        return StringCatalog(raw: raw)
    }

    /// Returns all locale identifiers that have at least one translation.
    public var locales: [String] {
        var result = Set<String>()
        for entry in strings.values {
            for locale in entry.localizations.keys {
                result.insert(locale)
            }
        }
        return result.sorted()
    }

    /// Extracts a flat `[key: value]` translation table for the given locale.
    ///
    /// Only includes entries where the locale has a `"translated"` string unit.
    /// Entries without a translation for the requested locale are omitted
    /// (the ``Localization`` fallback chain handles missing keys).
    ///
    /// - Parameter locale: The locale identifier (e.g. `"en"`, `"es"`).
    /// - Returns: A dictionary of translation key to translated string.
    public func translations(for locale: String) -> [String: String] {
        var table: [String: String] = [:]
        for (key, entry) in strings {
            if let localization = entry.localizations[locale] {
                table[key] = localization.stringUnit.value
            }
        }
        return table
    }
}

// MARK: - JSON Decoding

/// Internal Codable representation matching the `.xcstrings` JSON schema.
private struct RawCatalog: Decodable {
    let sourceLanguage: String
    let version: String
    let strings: [String: RawStringEntry]
}

private struct RawStringEntry: Decodable {
    let comment: String?
    let localizations: [String: RawLocalizationValue]?
}

private struct RawLocalizationValue: Decodable {
    let stringUnit: RawStringUnit?
}

private struct RawStringUnit: Decodable {
    let state: String
    let value: String
}

extension StringCatalog {
    fileprivate init(raw: RawCatalog) {
        self.sourceLanguage = raw.sourceLanguage
        self.version = raw.version

        var entries: [String: StringEntry] = [:]
        for (key, rawEntry) in raw.strings {
            var localizations: [String: LocalizationValue] = [:]
            if let rawLocalizations = rawEntry.localizations {
                for (locale, rawValue) in rawLocalizations {
                    if let unit = rawValue.stringUnit {
                        localizations[locale] = LocalizationValue(
                            stringUnit: StringUnit(
                                state: unit.state,
                                value: unit.value
                            )
                        )
                    }
                }
            }
            entries[key] = StringEntry(
                comment: rawEntry.comment,
                localizations: localizations
            )
        }
        self.strings = entries
    }
}
