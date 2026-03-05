import Score

struct DocLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Score Docs" }
            }
            NavBarContent {
                NavItem(href: "/") { Text { "Docs" } }
            }
            NavBarActions {
                ThemeSwitcher()
            }
        }
        Stack {
            Sidebar()
            Main {
                content
            }
        }
    }
}
