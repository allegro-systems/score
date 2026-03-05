import Score

@main
struct CalculatorApp: Application {
    var pages: [any Page] {
        [Calculator()]
    }

    static func main() async throws {
        try await CalculatorApp().run()
    }
}
