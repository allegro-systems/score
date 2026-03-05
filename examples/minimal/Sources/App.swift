import Score

@main
struct MinimalApp: Application {
    var metadata: Metadata? {
        Metadata(
            title: "Minimal App",
            description: "A minimal application using Score."
        )
    }

    var pages: [any Page] {
        [Home()]
    }

    var controllers: [any Controller] {
        [APIController()]
    }

    static func main() async throws {
        try await MinimalApp().run()
    }
}
