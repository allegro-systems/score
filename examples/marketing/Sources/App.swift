import Score

@main
struct MarketingApp: Application {
    var pages: [any Page] {
        [
            Landing(),
            Features(),
            Pricing(),
            Contact(),
        ]
    }

    var metadata: Metadata? {
        Metadata(
            site: "Acme",
            titleSeparator: " — ",
            description: "Ship faster with Acme.",
            keywords: ["acme", "saas", "platform"]
        )
    }

    static func main() async throws {
        try await MarketingApp().run()
    }
}
