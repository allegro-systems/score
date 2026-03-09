import Score

@main
struct TaskBoardApp: Application {
    var pages: [any Page] {
        [Board()]
    }

    var controllers: [any Controller] {
        [TaskController()]
    }

    var metadata: Metadata? {
        Metadata(
            site: "Task Board",
            description: "A kanban task board built with Score.",
            keywords: ["score", "swift", "taskboard", "kanban"]
        )
    }

    static func main() async throws {
        try await TaskBoardApp().run()
    }
}
