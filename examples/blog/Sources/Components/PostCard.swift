import ScoreRuntime

struct PostCard: Component {
    let title: String
    let slug: String
    let excerpt: String

    var body: some Node {
        Article {
            Heading(.two) {
                Link(to: "/posts/\(slug)") { title }
                    .font(color: .accent, decoration: TextDecoration.none)
            }
            .font(size: 18, weight: .medium, color: .text)
            Paragraph { excerpt }
                .font(size: 13, color: .muted)
                .margin(4, at: .top)
        }
        .padding(16, at: .vertical)
        .border(width: 1, color: .border, style: .solid, at: [.bottom])
    }
}
