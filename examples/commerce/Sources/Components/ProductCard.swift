import ScoreRuntime

struct ProductCard: Component {
    let product: Product

    var body: some Node {
        Article {
            Heading(.three) { product.name }
            Paragraph { product.description }
            Paragraph {
                Strong { product.price }
            }
            Link(to: "/products/\(product.id)") {
                "View Details"
            }
        }
    }
}
