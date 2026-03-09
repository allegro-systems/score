import ScoreRuntime

struct ProductGrid: Component {
    let products: [Product]

    var body: some Node {
        Section {
            ForEachNode(products) { product in
                ProductCard(product: product)
            }
        }
    }
}
