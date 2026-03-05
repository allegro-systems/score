import Score

struct SiteLayout<Content: Node>: Component {
    let locale: String
    let content: Content

    init(locale: String = "en", @NodeBuilder content: () -> Content) {
        self.locale = locale
        self.content = content()
    }

    var body: some Node {
        NavBar {
            NavBarBrand {
                Text { "Localised" }
            }
            NavBarContent {
                NavItem(href: "/") { Text { "Home" } }
                NavItem(href: "/about") { Text { "About" } }
            }
            NavBarActions {
                for loc in locales {
                    Link(to: "?lang=\(loc)") {
                        Badge(loc == locale ? .default : .outline) {
                            Text { loc.uppercased() }
                        }
                    }
                }
            }
        }
        Main {
            content
        }
    }
}

private let locales: [String] = ["en", "es", "it", "de", "ru"]
