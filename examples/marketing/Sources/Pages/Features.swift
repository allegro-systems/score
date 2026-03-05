import Score

struct Features: Page {
    static let path = "/features"

    var metadata: Metadata? {
        Metadata(title: "Features", description: "Explore Acme's features for building and deploying web applications.")
    }

    var body: some Node {
        SiteHeader()
        Main {
            Section {
                Heading(.one) { Text { "Features" } }
                Paragraph {
                    Text { "Everything you need to build, deploy, and scale." }
                }
            }
            FeatureGrid()
            Section {
                Heading(.two) { Text { "Built for Scale" } }
                Paragraph {
                    Text { "Acme handles traffic spikes automatically. No manual scaling, no cold starts, no surprises." }
                }
            }
            Section {
                Heading(.two) { Text { "Developer First" } }
                Paragraph {
                    Text { "Git push to deploy. Preview environments for every branch. Instant rollbacks when things go wrong." }
                }
            }
            CallToAction(
                headline: "See it in action",
                buttonText: "View Demo"
            )
        }
        SiteFooter()
    }
}
