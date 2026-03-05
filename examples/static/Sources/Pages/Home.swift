import Score

struct Home: Page {
    static let path = "/"

    var metadata: Metadata? {
        Metadata(title: "Home", description: "A pure HTML/CSS site built with Score.")
    }

    var body: some Node {
        PageLayout {
            Section {
                Heading(.one) { Text { "Welcome" } }
                Paragraph {
                    Text { "This is a pure HTML/CSS site with no JavaScript. It demonstrates multi-page routing, component composition, and responsive design — all rendered server-side by Score." }
                }
            }
            Section {
                Heading(.two) { Text { "Features" } }
                UnorderedList {
                    ListItem { Text { "Multi-page routing with clean URLs" } }
                    ListItem { Text { "Reusable components via the Component protocol" } }
                    ListItem { Text { "Theme-driven design tokens" } }
                    ListItem { Text { "SEO metadata on every page" } }
                    ListItem { Text { "Zero client-side JavaScript" } }
                }
            }
        }
    }
}
