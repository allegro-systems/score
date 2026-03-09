import ScoreAuth
import ScoreContent
import ScoreRuntime
import ScoreVendor

@main
struct FullApp: Application {
    var metadata: (any Metadata)? {
        SiteMetadata(
            site: "Score App",
            title: "Home",
            description: "A full-featured Score application"
        )
    }

    var theme: (any Theme)? { AppTheme() }

    var controllers: [any Controller] {
        [
            AuthController(),
            PostController(),
            UserController(),
            PaymentController(vendor: StripeVendor(apiKey: "sk_test_example")),
        ]
    }

    @PageBuilder
    var pages: [any Page] {
        HomePage()
        BlogPage()
        DashboardPage()
        ProfilePage()
        SettingsPage()
    }
}
