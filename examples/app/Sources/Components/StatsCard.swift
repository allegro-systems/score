import ScoreRuntime

struct StatsCard: Component {
    let label: String
    let value: String

    var body: some Node {
        Section {
            Paragraph { Small { label } }
                .font(size: 11, color: .muted, transform: .uppercase)
            Heading(.two) { value }
                .font(size: 24, weight: .bold, color: .text)
                .margin(4, at: .top)
        }
        .padding(16)
        .border(width: 1, color: .border, style: .solid)
        .radius(8)
    }
}
