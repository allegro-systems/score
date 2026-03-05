import Score

struct TaskCard: Component {
    let title: String
    let priority: String
    let status: String

    var body: some Node {
        Card {
            CardContent {
                Stack {
                    Text { title }
                    Stack {
                        Badge(badgeVariant(for: priority)) { Text { priority } }
                        Badge(statusVariant(for: status)) { Text { status } }
                    }
                }
            }
        }
    }

    private func badgeVariant(for priority: String) -> BadgeVariant {
        switch priority {
        case "high": .destructive
        case "medium": .warning
        default: .default
        }
    }

    private func statusVariant(for status: String) -> BadgeVariant {
        switch status {
        case "done": .success
        case "in_progress": .outline
        default: .default
        }
    }
}
