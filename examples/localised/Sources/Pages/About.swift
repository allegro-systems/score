import Score

struct About: Page {
    static let path = "/about"

    var body: some Node {
        SiteLayout(locale: "en") {
            Section {
                Heading(.one) { Text { "About" } }
                Paragraph {
                    Text { "This example shows how Score handles internationalisation. Locale-specific content is served based on the user's language preference. Dates, numbers, and currencies can be formatted per locale." }
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Formatted Content Examples" } }
                    }
                    CardContent {
                        UnorderedList {
                            ListItem {
                                Strong { Text { "Date: " } }
                                Text { "2 March 2026 (en) / 2 de marzo de 2026 (es)" }
                            }
                            ListItem {
                                Strong { Text { "Number: " } }
                                Text { "1,234.56 (en) / 1.234,56 (de)" }
                            }
                            ListItem {
                                Strong { Text { "Currency: " } }
                                Text { "$1,234.56 (en) / 1.234,56 € (de)" }
                            }
                        }
                    }
                }
            }
        }
    }
}
