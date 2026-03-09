import ScoreRuntime

struct LoginForm: Element {
    var body: some Node {
        Form(action: "/auth/login", method: .post) {
            Label(for: "email") { "Email" }
            Input(type: .email, name: "email")
            Label(for: "password") { "Password" }
            Input(type: .password, name: "password")
            Button { "Sign In" }
        }
    }
}
