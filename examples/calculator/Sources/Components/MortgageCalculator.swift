import Foundation
import Score

struct MortgageCalculator: Component {
    @State var principal = 300_000.0
    @State var rate = 6.5
    @State var term = 30

    @Action var updatePrincipal = {}
    @Action var updateRate = {}
    @Action var updateTerm = {}

    @Computed var monthlyRate: Double { rate / 100.0 / 12.0 }
    @Computed var totalPayments: Int { term * 12 }

    @Computed var monthlyPayment: Double {
        guard monthlyRate > 0, totalPayments > 0 else { return 0 }
        let r = monthlyRate
        let n = Double(totalPayments)
        return principal * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
    }

    @Computed var totalCost: Double { monthlyPayment * Double(totalPayments) }
    @Computed var totalInterest: Double { totalCost - principal }

    var body: some Node {
        Stack {
            Card {
                CardHeader {
                    CardTitle { Text { "Loan Details" } }
                }
                CardContent {
                    Stack {
                        InputField(
                            label: "Loan Amount ($)",
                            name: "principal",
                            type: .number,
                            value: "\(Int(principal))"
                        )
                        .on(.input, "updatePrincipal")

                        InputField(
                            label: "Annual Interest Rate (%)",
                            name: "rate",
                            type: .number,
                            value: "\(rate)"
                        )
                        .on(.input, "updateRate")

                        InputField(
                            label: "Loan Term (years)",
                            name: "term",
                            type: .number,
                            value: "\(term)"
                        )
                        .on(.input, "updateTerm")
                    }
                }
            }

            Card {
                CardHeader {
                    CardTitle { Text { "Results" } }
                }
                CardContent {
                    Stack {
                        Stack {
                            Text { "Monthly Payment" }
                            Heading(.two) {
                                Text { "$\(String(format: "%.2f", monthlyPayment))" }
                            }
                        }
                        Separator()
                        Paragraph {
                            Strong { Text { "Total Cost: " } }
                            Text { "$\(String(format: "%.2f", totalCost))" }
                        }
                        Paragraph {
                            Strong { Text { "Total Interest: " } }
                            Text { "$\(String(format: "%.2f", totalInterest))" }
                        }
                    }
                }
            }

            Card {
                CardHeader {
                    CardTitle { Text { "Amortization Schedule (Year 1)" } }
                    CardDescription { Text { "First 12 months of payments" } }
                }
                CardContent {
                    for row in scheduleRows {
                        Stack {
                            Text { "Month \(row.month)" }
                            Text { "Payment: $\(row.payment)" }
                            Text { "Principal: $\(row.principalPortion)" }
                            Text { "Interest: $\(row.interestPortion)" }
                            Text { "Balance: $\(row.balance)" }
                        }
                    }
                }
            }
        }
    }

    private var scheduleRows: [AmortizationRow] {
        guard monthlyRate > 0, totalPayments > 0 else { return [] }
        let payment = monthlyPayment
        var balance = principal
        var rows: [AmortizationRow] = []
        for month in 1...min(12, totalPayments) {
            let interest = balance * monthlyRate
            let principalPortion = payment - interest
            balance -= principalPortion
            rows.append(
                AmortizationRow(
                    month: month,
                    payment: String(format: "%.2f", payment),
                    principalPortion: String(format: "%.2f", principalPortion),
                    interestPortion: String(format: "%.2f", interest),
                    balance: String(format: "%.2f", max(0, balance))
                ))
        }
        return rows
    }
}

struct AmortizationRow: Sendable {
    let month: Int
    let payment: String
    let principalPortion: String
    let interestPortion: String
    let balance: String
}
