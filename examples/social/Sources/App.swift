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

    static func main() async throws {
        try await SocialApp().run()
    }
}
