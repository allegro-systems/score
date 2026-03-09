import ScoreRuntime
import ScoreVendor

@main
struct CommerceApp: Application {
    var metadata: (any Metadata)? {
        SiteMetadata(site: "Score Commerce", title: "Shop", description: "An e-commerce store built with Score")
    }

    var controllers: [any Controller] {
        [
            CartController(),
            OrderController(),
            PaymentController(vendor: StripeVendor(apiKey: "sk_test_example")),
        ]
    }

    @PageBuilder
    var pages: [any Page] {
        ProductsPage()
        ProductDetailPage()
        CartPage()
        CheckoutPage()
    }
}
