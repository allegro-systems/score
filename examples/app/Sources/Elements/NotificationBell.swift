import ScoreRuntime

struct NotificationBell: Element {
    @State var unread = 3

    @Action func markRead() {}

    var body: some Node {
        Button {
            Text { "Notifications (\(unread))" }
        }.on(.click, action: "markRead")
    }
}
