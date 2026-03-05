import Score

struct Home: Page {
    static let path = "/"

    var body: some Node {
        PostLayout {
            Section {
                Heading(.one) { Text { "Posts" } }
            }
            for post in samplePosts {
                PostCard(
                    title: post.title,
                    slug: post.slug,
                    summary: post.summary,
                    date: post.date
                )
            }
        }
    }
}

private let samplePosts: [BlogPost] = [
    BlogPost(
        title: "Getting Started with Score",
        slug: "getting-started",
        summary: "A step-by-step guide to creating your first Score application from scratch.",
        date: "2026-01-20"
    ),
    BlogPost(
        title: "Hello, World",
        slug: "hello-world",
        summary: "Welcome to the Score blog example. This post introduces the framework and shows how content collections work.",
        date: "2026-01-15"
    ),
]

struct BlogPost: Sendable {
    let title: String
    let slug: String
    let summary: String
    let date: String
}
