import Score

@main
struct TaskBoardApp: Application {
    var pages: [any Page] {
        [Board()]
    }

    var controllers: [any Controller] {
        [TaskController()]
    }

    static func main() async throws {
        try await TaskBoardApp().run()
    }
}
