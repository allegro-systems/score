import Score

struct DashboardLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Acme" }
            }
            NavBarContent {
                NavItem(href: "/dashboard") { Text { "Dashboard" } }
                NavItem(href: "/settings") { Text { "Settings" } }
            }
            NavBarActions {
                StyledButton(.ghost) { Text { "Sign Out" } }
            }
        }
        Main {
            content
        }
    }
}
