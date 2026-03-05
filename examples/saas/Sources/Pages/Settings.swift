import Score

struct Settings: Page {
    static let path = "/settings"

    var body: some Node {
        DashboardLayout {
            Section {
                Heading(.one) { Text { "Settings" } }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Profile" } }
                    }
                    CardContent {
                        Form(action: "/api/users/me", method: .post) {
                            InputField(label: "Display Name", name: "name", value: "Jane Smith")
                            InputField(label: "Email", name: "email", type: .email, value: "jane@example.com")
                            StyledButton(.default, type: .submit) { Text { "Save Changes" } }
                        }
                    }
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Billing" } }
                        CardDescription { Text { "Manage your subscription and payment method." } }
                    }
                    CardContent {
                        Paragraph {
                            Text { "Current plan: " }
                            Badge(.success) { Text { "Pro" } }
                        }
                        StyledButton(.outline) { Text { "Manage Subscription" } }
                    }
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Danger Zone" } }
                    }
                    CardContent {
                        StyledButton(.destructive) { Text { "Delete Account" } }
                    }
                }
            }
        }
    }
}
