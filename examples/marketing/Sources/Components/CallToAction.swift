import Score

struct CallToAction: Component {
    let headline: String
    let buttonText: String

    var body: some Node {
        Section {
            Heading(.two) { Text { headline } }
            StyledButton(.default, size: .large) { Text { buttonText } }
        }
    }
}
