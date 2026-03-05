import Score

struct About: Page {
    static let path = "/about"

    var metadata: Metadata? {
        Metadata(title: "About", description: "Learn how the static Score example works.")
    }

    var body: some Node {
        PageLayout {
            Section {
                Heading(.one) { Text { "About" } }
                Paragraph {
                    Text { "This example is the floor — pure server-rendered HTML and CSS with no JavaScript, no API controllers, and no client-side state. Everything you see is composed from Score's Node tree and rendered to static markup at request time." }
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "How it works" } }
                    }
                    CardContent {
                        OrderedList {
                            ListItem { Text { "Define pages with the Page protocol" } }
                            ListItem { Text { "Compose UI with Component and Node types" } }
                            ListItem { Text { "Set up a Theme for design tokens" } }
                            ListItem { Text { "Score renders HTML + CSS on the server" } }
                        }
                    }
                }
            }
        }
    }
}
