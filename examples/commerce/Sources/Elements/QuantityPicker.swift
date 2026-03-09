import ScoreRuntime

struct QuantityPicker: Element {
    @State var quantity = 1

    @Action func increment() {}

    @Action func decrement() {}

    var body: some Node {
        Stack {
            Button { "-" }
                .on(.click, action: "decrement")
            Text { "\(quantity)" }
            Button { "+" }
                .on(.click, action: "increment")
        }
    }
}
