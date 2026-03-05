import Score

struct ThemeSwitcher: Component {
    @State var currentTheme = "light"

    @Action var cycleTheme = {}

    var body: some Node {
        StyledButton(.ghost) { Text { "Theme: \(currentTheme)" } }
            .on(.click, "cycleTheme")
    }
}
