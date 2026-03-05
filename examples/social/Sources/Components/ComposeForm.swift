import Score

struct ComposeForm: Component {
    var body: some Node {
        Card {
            CardContent {
                Form(action: "/api/posts", method: .post) {
                    TextArea(name: "content", placeholder: "What's on your mind?", rows: 3, required: true)
                    StyledButton(.default, type: .submit) { Text { "Post" } }
                }
            }
        }
    }
}
