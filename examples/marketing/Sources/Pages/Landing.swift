import Score

struct Landing: Page {
    static let path = "/"

    var body: some Node {
        SiteHeader()
        Main {
            Hero(
                headline: "Ship faster with Acme",
                subheadline: "The modern platform for building, deploying, and scaling web applications. Start in minutes, grow without limits."
            )
            FeatureGrid()
            Section {
                Heading(.two) { Text { "Trusted by developers" } }
                Testimonial(
                    quote: "Acme cut our deployment time from hours to seconds. The developer experience is unmatched.",
                    author: "Jane Smith",
                    role: "CTO at TechCorp"
                )
            }
            CallToAction(
                headline: "Ready to get started?",
                buttonText: "Start Free Trial"
            )
        }
        SiteFooter()
    }
}
