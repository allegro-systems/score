import Score

struct PageLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        SiteHeader()
        Main {
            content
        }
        SiteFooter()
    }
}
