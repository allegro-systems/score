/// Thread-local context that carries the active locale and translation
/// table during a rendering pass.
///
/// `LocalizationContext` is set by the rendering pipeline before rendering
/// each page and is read by ``Localized`` nodes and the ``t(_:)`` function
/// to resolve translations.
///
/// You do not typically interact with this type directly. It is managed by
/// `PageRenderer` and `StaticSiteEmitter`.
public final class LocalizationContext: Sendable {

    /// The active locale for the current rendering pass.
    public let locale: SiteLocale

    /// The localization configuration.
    public let localization: Localization

    /// Creates a localization context.
    public init(locale: SiteLocale, localization: Localization) {
        self.locale = locale
        self.localization = localization
    }

    /// Translates a key using the current context's locale.
    public func translate(_ key: String) -> String {
        localization.translate(key, locale: locale)
    }

    // MARK: - Task-Local Storage

    /// The current localization context for the active rendering pass.
    ///
    /// Returns `nil` when no localization is configured or outside of a
    /// rendering pass. Use `LocalizationContext.$current.withValue(_:operation:)`
    /// to scope a context to a rendering pass.
    @TaskLocal public static var current: LocalizationContext?
}
