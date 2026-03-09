import ScoreRuntime

struct AppLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        Stack {
            SiteHeader()
            Main { content }
                .padding(24, at: .horizontal)
                .padding(32, at: .vertical)
                .size(maxWidth: 960)
            SiteFooter()
        }
        .flex(.column)
    }
}
