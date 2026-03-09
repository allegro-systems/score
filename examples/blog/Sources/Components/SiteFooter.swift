import ScoreRuntime

struct SiteFooter: Component {
    var body: some Node {
        Footer {
            Paragraph {
                Small { "Built with Score — a Swift web framework." }
            }
            .font(size: 11, color: .muted)
        }
        .padding(24, at: .vertical)
        .border(width: 1, color: .border, style: .solid, at: [.top])
    }
}
