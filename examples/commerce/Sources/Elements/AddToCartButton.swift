import ScoreRuntime

struct AddToCartButton: Element {
    @State var added = false

    @Action func addToCart() {}

    var body: some Node {
        Button {
            Text { added ? "Added!" : "Add to Cart" }
        }.on(.click, action: "addToCart")
    }
}
