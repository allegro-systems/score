import ScoreRuntime

struct ThemeToggle: Element {
    @State var isDarkMode = false

    @Action func toggleTheme() {}

    var body: some Node {
        Button {
            Text { isDarkMode ? "Light Mode" : "Dark Mode" }
        }.on(.click, action: "toggleTheme")
    }
}
