import ScoreRuntime

struct HomePage: Page {
    static let path = "/"

    var body: some Node {
        Main {
            SiteHeader()
            Section {
                Heading(.one) { "Latest Posts" }
                    .font(.serif, size: 28, weight: .light, color: .text)
                    .margin(0, at: .bottom)

                for post in Post.all {
                    PostCard(title: post.title, slug: post.slug, excerpt: post.excerpt)
                }
            }
            .padding(32, at: .vertical)
            SiteFooter()
        }
    }
}

struct Post: Sendable {
    let title: String
    let slug: String
    let excerpt: String
    let body: String

    static let all: [Post] = [
        Post(
            title: "Getting Started with Score",
            slug: "getting-started",
            excerpt: "Learn how to build your first Score application.",
            body: "# Getting Started with Score\n\nScore is a server-rendered Swift web framework."
        ),
        Post(
            title: "Building Components",
            slug: "building-components",
            excerpt: "Compose reusable UI with Score components.",
            body: "# Building Components\n\nComponents in Score are simple structs conforming to `Component`."
        ),
        Post(
            title: "Theming Your App",
            slug: "theming",
            excerpt: "Customize colors, typography, and spacing with Score themes.",
            body: "# Theming Your App\n\nScore themes use design tokens mapped to CSS custom properties."
        ),
    ]
}
