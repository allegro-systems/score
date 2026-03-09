import ScoreRuntime

struct CartPage: Page {
    static let path = "/cart"

    var body: some Node {
        Main {
            Navigation {
                Link(to: "/") { "Continue Shopping" }
            }
            Section {
                Heading(.one) { "Shopping Cart" }
                CartSummary()
                Link(to: "/checkout") {
                    "Proceed to Checkout"
                }
            }
        }
    }
}
