import ScoreRuntime

struct LoginPage: Page {
    static let path = "/login"

    var body: some Node {
        Main {
            Section {
                Heading(.one) {
                    "Sign In"
                }
                LoginForm()
                Paragraph {
                    Small {
                        "Don't have an account? "
                        Link(to: "/signup") { "Sign up" }
                    }
                }
            }
        }
    }
}
