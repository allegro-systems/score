/// Configuration for analytics script injection.
///
/// `AnalyticsProvider` encapsulates the scripts required by a specific
/// analytics vendor. Use one of the provided static factory methods to
/// create a provider for common services, or build a custom configuration
/// with ``custom(name:src:attributes:)``.
///
/// ### Example
///
/// ```swift
/// let ga = AnalyticsProvider.googleAnalytics(measurementID: "G-XXXXXXXXXX")
/// let plausible = AnalyticsProvider.plausible(domain: "example.com")
/// ```
public struct AnalyticsProvider: Sendable {

    /// A human-readable name identifying the analytics vendor.
    public let name: String

    /// The scripts required by this analytics provider.
    ///
    /// These scripts are intended to be collected by the page renderer and
    /// injected into the document head or body at assembly time.
    public let scripts: [Script]

    /// Creates an analytics provider with a custom name and scripts.
    ///
    /// - Parameters:
    ///   - name: A human-readable name for the provider.
    ///   - scripts: The scripts required by this provider.
    public init(name: String, scripts: [Script]) {
        self.name = name
        self.scripts = scripts
    }

    /// Creates a Google Analytics provider.
    ///
    /// Emits the standard Google Analytics 4 (gtag.js) loading scripts:
    /// an async loader for the gtag library and an inline configuration
    /// script tag.
    ///
    /// - Parameter measurementID: The GA4 measurement ID (e.g.
    ///   `"G-XXXXXXXXXX"`).
    /// - Returns: An `AnalyticsProvider` configured for Google Analytics.
    public static func googleAnalytics(measurementID: String) -> AnalyticsProvider {
        AnalyticsProvider(
            name: "Google Analytics",
            scripts: [
                Script(
                    src: "https://www.googletagmanager.com/gtag/js?id=\(measurementID)",
                    async: true
                )
            ]
        )
    }

    /// Creates a Plausible Analytics provider.
    ///
    /// Emits a single deferred script tag pointing to the Plausible
    /// tracking script with the appropriate `data-domain` attribute.
    ///
    /// - Parameter domain: The domain being tracked (e.g. `"example.com"`).
    /// - Returns: An `AnalyticsProvider` configured for Plausible Analytics.
    public static func plausible(domain: String) -> AnalyticsProvider {
        AnalyticsProvider(
            name: "Plausible",
            scripts: [
                Script(
                    src: "https://plausible.io/js/script.js",
                    defer: true,
                    attributes: ["data-domain": domain]
                )
            ]
        )
    }

    /// Creates a custom analytics provider with a single script.
    ///
    /// Use this factory for analytics services that are not covered by the
    /// built-in providers.
    ///
    /// - Parameters:
    ///   - name: A human-readable name for the provider.
    ///   - src: The URL of the analytics script.
    ///   - attributes: Additional HTML attributes for the `<script>` tag.
    ///     Defaults to an empty dictionary.
    /// - Returns: An `AnalyticsProvider` configured with the given script.
    public static func custom(
        name: String,
        src: String,
        attributes: [String: String] = [:]
    ) -> AnalyticsProvider {
        AnalyticsProvider(
            name: name,
            scripts: [
                Script(src: src, attributes: attributes)
            ]
        )
    }
}
