import ScoreContent
import ScoreRuntime

struct BlogPage: Page {
    static let path = "/blog"

    var body: some Node {
        AppLayout {
            Section {
                Heading(.one) { "Blog" }
                    .font(size: 28, weight: .light, color: .text)

                Article {
                    MarkdownNode(
                        "# Hello from Markdown\n\nThis post is rendered with `MarkdownNode`.\n\n## Features\n\n- Server-rendered HTML\n- Syntax highlighting\n- Full CommonMark support"
                    )
                }
                .padding(24, at: .vertical)

                for post in posts {
                    PostCard(title: post.title, slug: post.slug, excerpt: post.excerpt)
                }
            }
        }
    }
}

private let posts: [(title: String, slug: String, excerpt: String)] = [
    ("Getting Started", "getting-started", "Learn the basics of building with Score."),
    ("Advanced Patterns", "advanced-patterns", "Explore components, elements, and theming."),
]
