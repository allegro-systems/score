import ScoreVendor

struct StripeVendor: Vendor {
    let apiKey: String

    var routes: [Route] {
        [
            Route(method: .post, path: "/stripe/checkout"),
            Route(method: .post, path: "/stripe/webhook"),
        ]
    }
}
