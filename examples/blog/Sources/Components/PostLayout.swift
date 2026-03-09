import ScoreRuntime

struct PostLayout<Content: Node>: Component {
    let content: Content

    init(@NodeBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some Node {
        Article { content }
            .padding(32, at: .vertical)
            .size(maxWidth: 640)
    }
}
