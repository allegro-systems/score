import ScoreRuntime

struct ProfilePage: Page {
    static let path = "/profile"

    var body: some Node {
        AppLayout {
            Heading(.one) { "Profile" }
                .font(size: 28, weight: .light, color: .text)

            ProfileCard(name: "Jane Developer", email: "jane@example.com", role: "Admin")

            Section {
                Heading(.two) { "Recent Activity" }
                    .font(size: 18, weight: .medium, color: .text)
                    .margin(24, at: .top)

                UnorderedList {
                    ListItem { "Published \"Getting Started\" post" }
                    ListItem { "Updated profile settings" }
                    ListItem { "Upgraded to Pro plan" }
                }
                .font(size: 13, color: .muted)
                .margin(8, at: .top)
            }
        }
    }
}
