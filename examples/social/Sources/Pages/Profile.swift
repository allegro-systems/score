import Score

struct Profile: Page {
    static let path = "/profile"

    var body: some Node {
        NavBar {
            NavBarBrand { Text { "Social" } }
            NavBarContent {
                NavItem(href: "/") { Text { "Feed" } }
                NavItem(href: "/profile") { Text { "Profile" } }
            }
        }
        Main {
            Section {
                Card {
                    CardContent {
                        Heading(.one) { Text { "Alice" } }
                        Paragraph { Text { "@alice" } }
                        Paragraph { Text { "Building with Score. Local-first advocate." } }
                        Badge(.default) { Text { "42 posts" } }
                    }
                }
            }
        }
    }
}
