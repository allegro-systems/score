import ScoreRuntime

struct ProductDetailPage: Page {
    static let path = "/products/:id"

    var body: some Node {
        Main {
            Navigation {
                Link(to: "/") { "Back to Products" }
                Link(to: "/cart") { "Cart" }
            }
            Article {
                Heading(.one) { "Product Detail" }
                Paragraph { "View product information and add to cart." }
                AddToCartButton()
            }
        }
    }
}
