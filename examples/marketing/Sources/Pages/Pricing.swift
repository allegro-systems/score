import Score

struct Pricing: Page {
    static let path = "/pricing"

    var metadata: Metadata? {
        Metadata(title: "Pricing", description: "Simple, transparent pricing for every team size.")
    }

    var body: some Node {
        SiteHeader()
        Main {
            Section {
                Heading(.one) { Text { "Pricing" } }
                Paragraph {
                    Text { "Simple, transparent pricing. No hidden fees." }
                }
            }
            Section {
                Stack {
                    PricingCard(
                        name: "Starter",
                        price: "Free",
                        period: "",
                        features: [
                            "1 project",
                            "1 GB storage",
                            "Community support",
                        ]
                    )
                    PricingCard(
                        name: "Pro",
                        price: "$29",
                        features: [
                            "Unlimited projects",
                            "100 GB storage",
                            "Priority support",
                            "Custom domains",
                        ],
                        highlighted: true
                    )
                    PricingCard(
                        name: "Enterprise",
                        price: "Custom",
                        period: "",
                        features: [
                            "Unlimited everything",
                            "SSO & SAML",
                            "Dedicated support",
                            "SLA guarantee",
                        ]
                    )
                }
            }
        }
        SiteFooter()
    }
}
