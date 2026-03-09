import ScoreRuntime

struct ProfileCard: Component {
    let name: String
    let email: String
    let role: String

    var body: some Node {
        Section {
            Heading(.two) { name }
                .font(size: 20, weight: .medium, color: .text)
            Paragraph { email }
                .font(size: 13, color: .muted)
                .margin(4, at: .top)
            Paragraph {
                Small { role }
            }
            .font(size: 11, color: .accent)
            .margin(4, at: .top)
        }
        .padding(16)
        .border(width: 1, color: .border, style: .solid)
        .radius(8)
        .margin(16, at: .top)
    }
}
