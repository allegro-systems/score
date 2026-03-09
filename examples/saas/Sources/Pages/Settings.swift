import ScoreRuntime

struct SettingsPage: Page {
    static let path = "/settings"

    var body: some Node {
        DashboardLayout {
            Heading(.one) {
                "Settings"
            }
            Form(action: "/api/user/update", method: .post) {
                Label(for: "name") { "Name" }
                Input(type: .text, name: "name")
                Label(for: "email") { "Email" }
                Input(type: .email, name: "email")
                Button { "Save Changes" }
            }
        }
    }
}
