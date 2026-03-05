import Score

struct StatsCard: Component {
    let label: String
    let value: String
    let trend: String

    var body: some Node {
        Card {
            CardHeader {
                CardDescription { Text { label } }
            }
            CardContent {
                Heading(.two) { Text { value } }
                Paragraph {
                    Small { Text { trend } }
                }
            }
        }
    }
}
