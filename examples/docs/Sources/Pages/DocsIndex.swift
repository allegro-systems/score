import Score

struct DocsIndex: Page {
    static let path = "/"

    var body: some Node {
        DocLayout {
            Section {
                Heading(.one) { Text { "Introduction" } }
                Paragraph {
                    Text { "Welcome to the Score documentation. Score is a Swift web framework that brings SwiftUI-style declarative composition to server-side HTML rendering." }
                }
            }
            Section {
                Heading(.two) { Text { "Quick Start" } }
                Preformatted {
                    Code {
                        Text { """
                        score init MyApp --template minimal
                        cd MyApp
                        swift run
                        """ }
                    }
                }
            }
            Section {
                Heading(.two) { Text { "Core Concepts" } }
                UnorderedList {
                    ListItem {
                        Strong { Text { "Application" } }
                        Text { " — the root configuration wiring pages, theme, and controllers" }
                    }
                    ListItem {
                        Strong { Text { "Page" } }
                        Text { " — a URL route with a declarative body" }
                    }
                    ListItem {
                        Strong { Text { "Component" } }
                        Text { " — a reusable UI building block" }
                    }
                    ListItem {
                        Strong { Text { "Theme" } }
                        Text { " — design tokens for colors, typography, and spacing" }
                    }
                }
            }
        }
    }
}
