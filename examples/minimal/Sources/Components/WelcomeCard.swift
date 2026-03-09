import ScoreRuntime

struct WelcomeCard: Component {
    var body: some Node {
        Section {
            Heading(.one) { "Welcome to Score" }
                .font(.serif, size: 28, weight: .light, color: .text)
            Paragraph { "This is a minimal example showing a single page, component, controller, and custom theme." }
                .font(size: 14, color: .muted)
                .margin(8, at: .top)
        }
    }
}
