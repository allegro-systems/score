import Score

struct Post: Page {
    static let path = "/blog/:slug"

    var metadata: Metadata? {
        Metadata(
            title: "Hello, World",
            description: "Welcome to the Score blog example.",
            keywords: ["score", "swift", "blog"]
        )
    }

    var body: some Node {
        PostLayout {
            Article {
                Section {
                    Heading(.one) { Text { "Hello, World" } }
                    Paragraph {
                        Small { Text { "January 15, 2026" } }
                    }
                }
                Section {
                    Paragraph {
                        Text { "Welcome to the " }
                        Strong { Text { "Score Blog" } }
                        Text {
                            " example. This project demonstrates how to build a content-driven site with Score using content collections, front matter metadata, markdown rendering, and per-page SEO overrides."
                        }
                    }
                    Heading(.two) { Text { "Getting Started" } }
                    Paragraph {
                        Text {
                            "Create markdown files in Content/posts/ with YAML front matter at the top. Score's ContentCollection loads them automatically and gives you filtering, sorting, and tag extraction."
                        }
                    }
                    Heading(.two) { Text { "Code Example" } }
                    Preformatted {
                        Code {
                            Text { "let posts = try ContentCollection(directory: \"Content/posts\")\nlet latest = posts.sorted(by: \"date\", ascending: false)" }
                        }
                    }
                }
                Section {
                    Separator()
                    Link(to: "/") {
                        Text { "← Back to posts" }
                    }
                }
            }
        }
    }
}
