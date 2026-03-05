import Score

struct Testimonial: Component {
    let quote: String
    let author: String
    let role: String

    var body: some Node {
        Card {
            CardContent {
                Blockquote {
                    Paragraph { Text { quote } }
                }
                Paragraph {
                    Strong { Text { author } }
                    Text { " — \(role)" }
                }
            }
        }
    }
}
