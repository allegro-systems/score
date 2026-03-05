import Score

struct SiteHeader: Component {
    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Acme" }
            }
            NavBarContent {
                NavItem(href: "/") { Text { "Home" } }
                NavItem(href: "/features") { Text { "Features" } }
                NavItem(href: "/pricing") { Text { "Pricing" } }
                NavItem(href: "/contact") { Text { "Contact" } }
            }
            NavBarActions {
                StyledButton(.default) { Text { "Get Started" } }
            }
        }
    }
}
