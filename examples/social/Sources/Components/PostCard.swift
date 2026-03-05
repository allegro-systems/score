import Score

struct PostCard: Component {
    let author: String
    let content: String
    let timestamp: String

    var body: some Node {
        Card {
            CardHeader {
                CardTitle { Text { author } }
                CardDescription { Text { timestamp } }
            }
            CardContent {
                Paragraph { Text { content } }
            }
        }
    }
}
