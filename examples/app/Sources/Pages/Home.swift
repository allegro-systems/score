import ScoreRuntime

struct HomePage: Page {
    static let path = "/"

    var body: some Node {
        AppLayout {
            Section {
                Heading(.one) { "Welcome" }
                    .font(size: 28, weight: .light, color: .text)
                Paragraph { "A full-featured Score application with content, auth, interactivity, and payments." }
                    .font(size: 14, color: .muted)
                    .margin(8, at: .top)

                Stack {
                    Link(to: "/blog") { "Read the blog" }
                        .font(size: 12, weight: .medium, color: .accent, decoration: TextDecoration.none)
                    Link(to: "/dashboard") { "Go to dashboard" }
                        .font(size: 12, weight: .medium, color: .accent, decoration: TextDecoration.none)
                }
                .flex(.row, gap: 16)
                .margin(16, at: .top)
            }
            .padding(48, at: .vertical)
        }
    }
}
