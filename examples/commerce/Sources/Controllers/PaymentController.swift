import ScoreRuntime
import ScoreVendor

struct PaymentController: Controller {
    let vendor: StripeVendor

    var base: String { "/api/payments" }

    var routes: [Route] {
        [
            Route(method: .post, path: "/checkout"),
            Route(method: .post, path: "/webhook"),
        ]
    }
}
