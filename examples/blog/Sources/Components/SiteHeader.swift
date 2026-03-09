import ScoreRuntime

struct SiteHeader: Component {
    var body: some Node {
        Header {
            Navigation {
                Link(to: "/") { "Swift Blog" }
                    .font(size: 14, weight: .bold, color: .text, decoration: TextDecoration.none)
                Link(to: "/") { "Home" }
                    .font(size: 12, color: .muted, decoration: TextDecoration.none)
            }
            .flex(.row, gap: 16)
        }
        .padding(16, at: .vertical)
        .border(width: 1, color: .border, style: .solid, at: [.bottom])
    }
}
