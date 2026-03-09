import ScoreRuntime

struct StatsCard: Component {
    let label: String
    let value: String

    var body: some Node {
        Section {
            Paragraph {
                Small { label }
            }
            Heading(.two) {
                value
            }
        }
    }
}
