import Score

@main
struct LocalisedApp: Application {
    var pages: [any Page] {
        [
            Home(),
            About(),
        ]
    }

    static func main() async throws {
        try await LocalisedApp().run()
    }
}
