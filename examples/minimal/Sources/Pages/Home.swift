import ScoreRuntime

struct HomePage: Page {
    static let path = "/"

    var body: some Node {
        Main {
            WelcomeCard()
            Paragraph { "Built with Score — a server-rendered Swift web framework." }
                .font(size: 13, color: .muted)
                .margin(16, at: .top)
            Link(to: "/api/status") { "Check API status" }
                .font(size: 11, weight: .medium, color: .accent, decoration: TextDecoration.none)
        }
        .padding(48, at: .vertical)
        .padding(24, at: .horizontal)
    }
}
