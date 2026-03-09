import ScoreRuntime

struct SettingsPage: Page {
    static let path = "/settings"

    var body: some Node {
        AppLayout {
            Heading(.one) { "Settings" }
                .font(size: 28, weight: .light, color: .text)

            Section {
                Heading(.two) { "Appearance" }
                    .font(size: 18, weight: .medium, color: .text)
                    .margin(24, at: .top)
                ThemeToggle()
            }

            Form(action: "/api/user/update", method: .post) {
                Fieldset {
                    Legend { "Account" }
                        .font(size: 14, weight: .medium, color: .text)
                    Label(for: "name") { "Name" }
                        .font(size: 12, color: .muted)
                    Input(type: .text, name: "name")
                    Label(for: "email") { "Email" }
                        .font(size: 12, color: .muted)
                    Input(type: .email, name: "email")
                }
                Button { "Save" }
                    .font(size: 12, weight: .medium, color: .surface)
                    .background(.accent)
                    .padding(8, at: .vertical)
                    .padding(16, at: .horizontal)
                    .radius(4)
                    .margin(16, at: .top)
            }
            .margin(24, at: .top)
        }
    }
}
