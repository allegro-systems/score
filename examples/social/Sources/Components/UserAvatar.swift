import Score

struct UserAvatar: Component {
    let name: String
    let imageURL: String

    var body: some Node {
        Avatar(src: imageURL, alt: name)
    }
}
