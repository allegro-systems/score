import Score

struct Contact: Page {
    static let path = "/contact"

    var metadata: Metadata? {
        Metadata(title: "Contact", description: "Get in touch.")
    }

    var body: some Node {
        PageLayout {
            Section {
                Heading(.one) { Text { "Contact" } }
                Paragraph {
                    Text { "This page shows a static contact section. In a real application you would add a Form with Input fields and a Controller to handle submissions." }
                }
            }
            Section {
                Card {
                    CardContent {
                        Paragraph {
                            Strong { Text { "Email: " } }
                            Link(to: "mailto:hello@example.com") {
                                Text { "hello@example.com" }
                            }
                        }
                        Separator()
                        Paragraph {
                            Strong { Text { "Source: " } }
                            Link(to: "https://github.com/allegro-systems/score") {
                                Text { "github.com/allegro-systems/score" }
                            }
                        }
                    }
                }
            }
        }
    }
}
