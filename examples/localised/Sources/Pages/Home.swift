import Score

struct Home: Page {
    static let path = "/"

    var body: some Node {
        SiteLayout(locale: "en") {
            LocaleAwareBanner(locale: "en")
            Section {
                Heading(.one) { Text { "Home" } }
                Paragraph {
                    Text { "This example demonstrates locale-aware rendering with 5 locales: English, Spanish, Italian, German, and Russian. Each locale has its own greetings and formatted content." }
                }
            }
            Section {
                Card {
                    CardHeader {
                        CardTitle { Text { "Supported Locales" } }
                    }
                    CardContent {
                        UnorderedList {
                            ListItem { Text { "🇬🇧 English (en) — source locale" } }
                            ListItem { Text { "🇪🇸 Español (es)" } }
                            ListItem { Text { "🇮🇹 Italiano (it)" } }
                            ListItem { Text { "🇩🇪 Deutsch (de)" } }
                            ListItem { Text { "🇷🇺 Русский (ru)" } }
                        }
                    }
                }
            }
        }
    }
}
