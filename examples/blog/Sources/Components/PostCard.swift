import Score

struct PostCard: Component {
    let title: String
    let slug: String
    let summary: String
    let date: String

    var body: some Node {
        Article {
            Card {
                CardHeader {
                    CardTitle {
                        Link(to: "/blog/\(slug)") {
                            Text { title }
                        }
                    }
                    CardDescription { Text { date } }
                }
                CardContent {
                    Paragraph { Text { summary } }
                }
                CardFooter {
                    Link(to: "/blog/\(slug)") {
                        Text { "Read more →" }
                    }
                }
            }
        }
    }
}
