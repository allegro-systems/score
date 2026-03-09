import ScoreRuntime

struct DashboardPage: Page {
    static let path = "/dashboard"

    var body: some Node {
        DashboardLayout {
            Heading(.one) {
                "Dashboard"
            }
            Section {
                StatsCard(label: "Users", value: "1,284")
                StatsCard(label: "Revenue", value: "$12,400")
                StatsCard(label: "Active Plans", value: "847")
            }
        }
    }
}
