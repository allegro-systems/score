import Score

struct SiteFooter: Component {
    var body: some Node {
        Footer {
            Separator()
            Paragraph {
                Small {
                    Text { "Powered by Score — the Swift web framework." }
                }
            }
        }
    }
}
