/// Resolves a translation key for the current locale.
///
/// `t()` is the single localization API in Score. It looks up the key in
/// the active ``LocalizationContext`` and returns the translated string.
/// When no context is active, returns the `default` value if provided,
/// or the key itself.
///
/// Use `t()` both in node builder bodies (Swift auto-wraps strings into
/// text nodes) and as component parameters:
///
/// ```swift
/// Heading(.one) { t("home.title") }
/// Paragraph { t("home.subtitle") }
///
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
