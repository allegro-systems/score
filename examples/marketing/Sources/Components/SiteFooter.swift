import Score

struct SiteFooter: Component {
    var body: some Node {
        Footer {
            Separator()
            Paragraph {
                Small { Text { "© 2026 Acme Inc. Built with Score." } }
            }
        }
    }
}
