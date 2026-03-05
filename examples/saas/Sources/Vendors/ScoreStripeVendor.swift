import Score

struct ScoreStripeVendor: VendorIntegration {
    let publishableKey: String

    var scripts: [Script] {
        [
            Script(src: "https://js.stripe.com/v3/"),
        ]
    }
}
