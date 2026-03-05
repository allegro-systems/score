import Score

@main
struct BlogApp: Application {
    var pages: [any Page] {
        [
            Home(),
            Post(),
        ]
    }

    var metadata: Metadata? {
        Metadata(
            site: "Score Blog",
            description: "A blog built with Score, featuring content collections and SEO metadata.",
            keywords: ["score", "swift", "blog", "web"]
        )
    }

    static func main() async throws {
        try await BlogApp().run()
    }
}
