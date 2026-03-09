import ScoreRuntime

struct SearchBar: Element {
    @State var query = ""

    @Action func search() {}

    var body: some Node {
        Form(action: "/api/posts", method: .get) {
            Input(type: .search, name: "q")
                .on(.input, action: "search")
        }
    }
}
