import Score

struct Dashboard: Page {
    static let path = "/dashboard"

    var body: some Node {
        DashboardLayout {
            Section {
                Heading(.one) { Text { "Dashboard" } }
            }
            Section {
                Stack {
                    StatsCard(label: "Total Users", value: "1,234", trend: "+12% from last month")
                    StatsCard(label: "Revenue", value: "$45,678", trend: "+8% from last month")
                    StatsCard(label: "Active Plans", value: "892", trend: "+5% from last month")
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Recent Activity" } }
                    }
                    CardContent {
                        UnorderedList {
                            ListItem { Text { "User jane@example.com upgraded to Pro" } }
                            ListItem { Text { "New signup: bob@example.com" } }
                            ListItem { Text { "Payment received: $29.00" } }
                        }
                    }
                }
            }
        }
    }
}
