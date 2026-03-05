import Score

struct Column<Content: Node>: Component {
    let title: String
    let count: Int
    let content: Content

    init(title: String, count: Int, @NodeBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.content = content()
    }

    var body: some Node {
        Section {
            Stack {
                Heading(.two) { Text { title } }
                Badge(.outline) { Text { "\(count)" } }
            }
            content
        }
    }
}
