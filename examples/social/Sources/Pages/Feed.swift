import Score

struct Feed: Page {
    static let path = "/"

    var body: some Node {
        NavBar {
            NavBarBrand { Text { "Social" } }
            NavBarContent {
                NavItem(href: "/") { Text { "Feed" } }
                NavItem(href: "/profile") { Text { "Profile" } }
            }
            NavBarActions {
                StyledButton(.default) { Text { "New Post" } }
            }
        }
        Main {
            Section {
                Heading(.one) { Text { "Feed" } }
            }
            Dialog {
                Heading(.two) { Text { "New Post" } }
                ComposeForm()
            }
            for post in samplePosts {
                PostCard(author: post.author, content: post.content, timestamp: post.timestamp)
            }
        }
    }
}

private let samplePosts: [SamplePost] = [
    SamplePost(author: "Alice", content: "Just shipped a new feature with Score. The declarative syntax is amazing!", timestamp: "2 hours ago"),
    SamplePost(author: "Bob", content: "Working on a local-first sync engine. CRDTs are fascinating.", timestamp: "5 hours ago"),
    SamplePost(author: "Carol", content: "TIL: Swift's result builders can handle for loops natively. No need for ForEach!", timestamp: "1 day ago"),
]

struct SamplePost: Sendable {
    let author: String
    let content: String
    let timestamp: String
}
