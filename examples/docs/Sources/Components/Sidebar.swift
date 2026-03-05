import Score

struct Sidebar: Component {
    var body: some Node {
        Aside {
            Navigation {
                Heading(.three) { Text { "Documentation" } }
                UnorderedList {
                    ListItem {
                        Link(to: "/") {
                            Text { "Introduction" }
                        }
                    }
                    ListItem {
                        Link(to: "/docs/getting-started") {
                            Text { "Getting Started" }
                        }
                    }
                    ListItem {
                        Link(to: "/docs/api-reference") {
                            Text { "API Reference" }
                        }
                    }
                }
            }
        }
    }
}
