import Score

struct SiteFooter: Component {
    var body: some Node {
        Footer {
            Paragraph {
                Small {
                    Text { "Built with Score — the Swift web framework." }
                }
            }
        }
    }
}
