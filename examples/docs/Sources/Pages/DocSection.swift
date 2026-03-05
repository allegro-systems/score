import Score

struct DocSection: Page {
    static let path = "/docs/:section"

    var metadata: Metadata? {
        Metadata(
            title: "Getting Started",
            description: "Get started with the Score Swift web framework."
        )
    }

    var body: some Node {
        DocLayout {
            Section {
                Heading(.one) { Text { "Getting Started" } }
                Paragraph {
                    Text { "This guide walks through the key concepts needed to build your first Score application." }
                }
            }
            Section {
                Heading(.two) { Text { "Prerequisites" } }
                UnorderedList {
                    ListItem { Text { "Swift 6.2 or later" } }
                    ListItem { Text { "macOS 14 or later" } }
                }
            }
            Section {
                Heading(.two) { Text { "Creating a Page" } }
                Paragraph {
                    Text { "Every route in Score is a Page. Pages declare a static path and a body that returns a node tree:" }
                }
                Preformatted {
                    Code {
                        Text { """
                        struct Home: Page {
                            static let path = "/"

                            var body: some Node {
                                Heading(.one) { Text { "Hello!" } }
                            }
                        }
                        """ }
                    }
                }
            }
            Section {
                Heading(.two) { Text { "Adding Components" } }
                Paragraph {
                    Text { "Components are reusable UI blocks. They conform to the Component protocol and compose other nodes in their body:" }
                }
                Preformatted {
                    Code {
                        Text { """
                        struct GreetingCard: Component {
                            let name: String

                            var body: some Node {
                                Card {
                                    CardContent {
                                        Text { "Hello, \\(name)!" }
                                    }
                                }
                            }
                        }
                        """ }
                    }
                }
            }
        }
    }
}
