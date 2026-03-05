import Score

struct FeatureGrid: Component {
    var body: some Node {
        Section {
            Heading(.two) { Text { "Everything you need" } }
            Stack {
                FeatureCard(
                    title: "Lightning Fast",
                    description: "Built on Swift NIO for minimal latency and maximum throughput."
                )
                FeatureCard(
                    title: "Type Safe",
                    description: "Catch errors at compile time. No runtime surprises."
                )
                FeatureCard(
                    title: "Beautiful by Default",
                    description: "ScoreUI components look great out of the box with customisable themes."
                )
            }
        }
    }
}

struct FeatureCard: Component {
    let title: String
    let description: String

    var body: some Node {
        Card {
            CardHeader {
                CardTitle { Text { title } }
            }
            CardContent {
                Paragraph { Text { description } }
            }
        }
    }
}
