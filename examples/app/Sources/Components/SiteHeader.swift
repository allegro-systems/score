import ScoreRuntime

struct SiteHeader: Component {
    var body: some Node {
        Header {
            Navigation {
                Link(to: "/") { "Score App" }
                    .font(size: 14, weight: .bold, color: .text, decoration: TextDecoration.none)

                for item in navItems {
                    Link(to: item.url) { item.label }
                        .font(size: 12, color: .muted, decoration: TextDecoration.none)
                }
            }
            .flex(.row, gap: 16)

            Stack {
                SearchBar()
                NotificationBell()
            }
            .flex(.row, gap: 8)
        }
        .flex(.row, gap: 16)
        .padding(16, at: .vertical)
        .padding(24, at: .horizontal)
        .border(width: 1, color: .border, style: .solid, at: [.bottom])
    }
}

private let navItems: [(label: String, url: String)] = [
    ("Blog", "/blog"),
    ("Dashboard", "/dashboard"),
    ("Profile", "/profile"),
    ("Settings", "/settings"),
]
