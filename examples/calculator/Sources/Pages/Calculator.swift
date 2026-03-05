import Score

struct Calculator: Page {
    static let path = "/"

    var metadata: Metadata? {
        Metadata(
            site: "Score Calculator",
            title: "Mortgage Calculator",
            titleSeparator: " | ",
            description: "Calculate your monthly mortgage payment with this interactive calculator.",
            keywords: ["mortgage", "calculator", "score", "swift"]
        )
    }

    var body: some Node {
        Main {
            Section {
                Heading(.one) { Text { "Mortgage Calculator" } }
                Paragraph {
                    Text { "Calculate your monthly mortgage payment. All computation happens client-side — no server round-trips." }
                }
            }
            MortgageCalculator()
        }
    }
}
