import Score

@main
struct SaaSApp: Application {
    var pages: [any Page] {
        [
            Login(),
            Dashboard(),
            Settings(),
        ]
    }

    var controllers: [any Controller] {
        [
            AuthController(),
            UserController(),
            BillingController(),
        ]
    }

    var metadata: Metadata? {
        Metadata(
            site: "Acme Dashboard",
            description: "Manage your Acme account.",
            keywords: ["saas", "dashboard", "score"]
        )
    }

    static func main() async throws {
        try await SaaSApp().run()
    }
}
