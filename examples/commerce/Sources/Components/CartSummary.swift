import ScoreRuntime

struct CartSummary: Component {
    var body: some Node {
        Section {
            Heading(.two) { "Order Summary" }
            Table {
                TableHead {
                    TableRow {
                        TableHeaderCell { "Item" }
                        TableHeaderCell { "Qty" }
                        TableHeaderCell { "Price" }
                    }
                }
                TableBody {
                    TableRow {
                        TableCell { "Your cart is empty" }
                        TableCell { "-" }
                        TableCell { "$0.00" }
                    }
                }
            }
        }
    }
}
