import ScoreRuntime

struct BillingPage: Page {
    static let path = "/billing"

    var body: some Node {
        DashboardLayout {
            Heading(.one) {
                "Billing"
            }
            Section {
                PricingCard(name: "Starter", price: "$9/mo", features: ["5 projects", "1 GB storage", "Email support"])
                PricingCard(name: "Pro", price: "$29/mo", features: ["Unlimited projects", "10 GB storage", "Priority support"])
                PricingCard(name: "Enterprise", price: "$99/mo", features: ["Unlimited everything", "SSO", "Dedicated support"])
            }
        }
    }
}
