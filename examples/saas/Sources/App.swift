import ScoreAuth
import ScoreRuntime
import ScoreVendor

@main
struct SaaSApp: Application {
    var metadata: (any Metadata)? {
        SiteMetadata(site: "SaaS App", title: "Dashboard", description: "A SaaS starter built with Score")
    }

    var controllers: [any Controller] {
        [
            AuthController(),
            UserController(),
            PaymentController(vendor: StripeVendor(apiKey: "sk_test_example")),
        ]
    }

    @PageBuilder
    var pages: [any Page] {
        LoginPage()
        DashboardPage()
        SettingsPage()
        BillingPage()
    }
}
