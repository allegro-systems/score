import ScoreContent
import ScoreRuntime

struct PostPage: Page {
    static let path = "/posts/:slug"

    var body: some Node {
        Main {
            SiteHeader()
            PostLayout {
                MarkdownNode("# Post Detail\n\nThis page renders individual blog posts using `MarkdownNode`.")
            }
            SiteFooter()
        }
    }
}
