import ScoreContent
import ScoreRuntime

@main
struct BlogApp: Application {
    var metadata: (any Metadata)? {
        SiteMetadata(
            site: "Swift Blog",
            title: "Home",
            description: "A blog built with Score"
        )
    }

    var theme: (any Theme)? { BlogTheme() }

    @PageBuilder
    var pages: [any Page] {
        HomePage()
        PostPage()
    }
}
