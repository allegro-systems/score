import ScoreRuntime

struct ProductsPage: Page {
    static let path = "/"

    var body: some Node {
        Main {
            Navigation {
                Link(to: "/") { "Score Commerce" }
                Link(to: "/cart") { "Cart" }
            }
            Section {
                Heading(.one) { "Products" }
                ProductGrid(products: Product.catalog)
            }
        }
    }
}

struct Product: Sendable {
    let id: String
    let name: String
    let price: String
    let description: String

    static let catalog: [Product] = [
        Product(id: "tee-1", name: "Score T-Shirt", price: "$29.00", description: "Soft cotton tee with the Score logo."),
        Product(id: "hoodie-1", name: "Swift Hoodie", price: "$59.00", description: "Cozy hoodie for late-night coding sessions."),
        Product(id: "mug-1", name: "Developer Mug", price: "$15.00", description: "Ceramic mug that holds your favorite beverage."),
        Product(id: "sticker-1", name: "Sticker Pack", price: "$8.00", description: "Set of 5 vinyl stickers for your laptop."),
    ]
}
