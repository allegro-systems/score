import ScoreRuntime

struct DashboardLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        Stack {
            Navigation {
                Link(to: "/dashboard") { "Dashboard" }
                Link(to: "/settings") { "Settings" }
                Link(to: "/billing") { "Billing" }
            }
            Main {
                content
            }
        }
    }
}
