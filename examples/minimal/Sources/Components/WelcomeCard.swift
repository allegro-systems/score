import Score

struct WelcomeCard: Component {
    var body: some Node {
        Card {
            CardHeader {
                CardTitle { Text { "Welcome to Score" } }
                CardDescription { Text { "A Swift web framework that feels like SwiftUI." } }
            }
            CardContent {
                Paragraph {
                    Text { "This is the minimal template — 1 page, 1 component, 1 API controller. Edit the source files to start building." }
                }
            }
            .padding(.all, 24)
            .background(.oklch(0.97, 0.005, 250))
            .cornerRadius(8)
            CardFooter {
                Badge(.success) { Text { "Running" } }
            }
        }
    }
}
