import ScoreRuntime

@main
struct MinimalApp: Application {
    var metadata: (any Metadata)? {
        SiteMetadata(site: "Minimal", title: "Home", description: "A minimal Score app")
    }

    var theme: (any Theme)? { AppTheme() }

    var controllers: [any Controller] { [APIController()] }

    @PageBuilder
    var pages: [any Page] {
        HomePage()
    }
}
