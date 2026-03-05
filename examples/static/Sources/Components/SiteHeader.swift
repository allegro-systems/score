import Score

struct SiteHeader: Component {
    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Static Site" }
            }
            NavBarContent {
                NavItem(href: "/") { Text { "Home" } }
                NavItem(href: "/about") { Text { "About" } }
                NavItem(href: "/contact") { Text { "Contact" } }
            }
        }
    }
}
