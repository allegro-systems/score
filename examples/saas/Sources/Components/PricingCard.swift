import ScoreRuntime

struct PricingCard: Component {
    let name: String
    let price: String
    let features: [String]

    var body: some Node {
        Section {
            Heading(.three) { name }
            Heading(.two) { price }
            UnorderedList {
                ForEachNode(features) { feature in
                    ListItem { feature }
                }
            }
            Link(to: "/api/payments/checkout") {
                "Subscribe"
            }
        }
    }
}
