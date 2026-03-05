import Score

struct Home: Page {
    static let path = "/"

    var metadata: Metadata? {
        Metadata(
            title: "Home",
            description: "A minimal Score application.",
            keywords: ["score", "swift", "web"]
        )
    }

    var body: some Node {
        Main {
            Section {
                WelcomeCard()
            }
        }
    }
}
