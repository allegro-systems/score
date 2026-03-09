import ScoreRuntime

struct DashboardPage: Page {
    static let path = "/dashboard"

    var body: some Node {
        AppLayout {
            Heading(.one) { "Dashboard" }
                .font(size: 28, weight: .light, color: .text)

            Section {
                for stat in stats {
                    StatsCard(label: stat.label, value: stat.value)
                }
            }
            .grid(columns: 3, gap: 16)
            .margin(24, at: .top)

            Section {
                Heading(.two) { "Quick Actions" }
                    .font(size: 18, weight: .medium, color: .text)
                    .margin(32, at: .top)

                Stack {
                    Link(to: "/settings") { "Settings" }
                        .font(size: 12, color: .accent, decoration: TextDecoration.none)
                    Link(to: "/profile") { "Profile" }
                        .font(size: 12, color: .accent, decoration: TextDecoration.none)
                }
                .flex(.row, gap: 16)
                .margin(8, at: .top)
            }
        }
    }
}

private let stats: [(label: String, value: String)] = [
    ("Posts", "42"),
    ("Subscribers", "1,280"),
    ("Revenue", "$8,400"),
]
