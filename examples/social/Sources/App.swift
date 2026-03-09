import Score

@main
struct SocialApp: Application {
    var pages: [any Page] {
        [
            Feed(),
            Profile(),
        ]
    }

    var controllers: [any Controller] {
        [
            PostController(),
            SocialUserController(),
        ]
    }

    var metadata: Metadata? {
        Metadata(
            site: "Social",
            description: "A social feed application built with Score.",
            keywords: ["score", "swift", "social", "web"]
        )
    }

    static func main() async throws {
        try await SocialApp().run()
    }
}
