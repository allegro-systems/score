import Score

struct SiteHeader: Component {
    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Score Blog" }
            }
            NavBarContent {
                NavItem(href: "/") { Text { "Posts" } }
            }
        }
    }
}
