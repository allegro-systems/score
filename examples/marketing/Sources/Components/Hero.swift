import Score

struct Hero: Component {
    let headline: String
    let subheadline: String

    var body: some Node {
        Section {
            Heading(.one) { Text { headline } }
            Paragraph { Text { subheadline } }
            Stack {
                StyledButton(.default, size: .large) {
                    Text { "Start Free Trial" }
                }
                StyledButton(.outline, size: .large) {
                    Text { "View Demo" }
                }
            }
        }
    }
}
