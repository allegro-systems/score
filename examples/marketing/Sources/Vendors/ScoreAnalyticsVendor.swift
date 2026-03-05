import Score

struct ScoreAnalyticsVendor: VendorIntegration {
    let measurementID: String

    var scripts: [Script] {
        [
            Script(
                src: "https://www.googletagmanager.com/gtag/js?id=\(measurementID)",
                async: true
            ),
        ]
    }
}
