import Score

struct PricingCard: Component {
    let name: String
    let price: String
    let period: String
    let features: [String]
    let highlighted: Bool

    init(name: String, price: String, period: String = "/month", features: [String], highlighted: Bool = false) {
        self.name = name
        self.price = price
        self.period = period
        self.features = features
        self.highlighted = highlighted
    }

    var body: some Node {
        Card {
            CardHeader {
                CardTitle { Text { name } }
                CardDescription {
                    Text { price }
                    Small { Text { period } }
                }
            }
            CardContent {
                UnorderedList {
                    for feature in features {
                        ListItem { Text { feature } }
                    }
                }
            }
            CardFooter {
                if highlighted {
                    StyledButton(.default) { Text { "Get Started" } }
                } else {
                    StyledButton(.outline) { Text { "Get Started" } }
                }
            }
        }
    }
}
