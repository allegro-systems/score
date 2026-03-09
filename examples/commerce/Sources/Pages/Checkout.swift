import ScoreRuntime

struct CheckoutPage: Page {
    static let path = "/checkout"

    var body: some Node {
        Main {
            Heading(.one) { "Checkout" }
            Form(action: "/api/orders/place", method: .post) {
                Fieldset {
                    Legend { "Shipping Address" }
                    Label(for: "name") { "Full Name" }
                    Input(type: .text, name: "name")
                    Label(for: "address") { "Address" }
                    Input(type: .text, name: "address")
                    Label(for: "email") { "Email" }
                    Input(type: .email, name: "email")
                }
                Button { "Place Order" }
            }
        }
    }
}
