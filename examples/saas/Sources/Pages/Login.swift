import Score

struct Login: Page {
    static let path = "/login"

    var body: some Node {
        Main {
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Sign In" } }
                        CardDescription { Text { "Enter your credentials to continue." } }
                    }
                    CardContent {
                        Form(action: "/api/auth/login", method: .post) {
                            InputField(label: "Email", name: "email", type: .email, placeholder: "you@example.com", required: true)
                            InputField(label: "Password", name: "password", type: .password, required: true)
                            StyledButton(.default, type: .submit) { Text { "Sign In" } }
                        }
                    }
                }
            }
        }
    }
}
