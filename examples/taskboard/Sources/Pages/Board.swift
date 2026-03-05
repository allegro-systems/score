import Score

struct Board: Page {
    static let path = "/"

    @State var tasks = sampleTasks

    @Action var addTask = {}

    var body: some Node {
        NavBar {
            NavBarBrand { Text { "TaskBoard" } }
            NavBarActions {
                StyledButton(.default) { Text { "New Task" } }
                    .on(.click, "addTask")
            }
        }
        Main {
            Stack {
                Column(title: "To Do", count: todoTasks.count) {
                    for task in todoTasks {
                        TaskCard(title: task.title, priority: task.priority, status: "To Do")
                    }
                }
                Column(title: "In Progress", count: inProgressTasks.count) {
                    for task in inProgressTasks {
                        TaskCard(title: task.title, priority: task.priority, status: "In Progress")
                    }
                }
                Column(title: "Done", count: doneTasks.count) {
                    for task in doneTasks {
                        TaskCard(title: task.title, priority: task.priority, status: "Done")
                    }
                }
            }
        }
    }

    private var todoTasks: [SampleTask] {
        tasks.filter { $0.status == "todo" }
    }

    private var inProgressTasks: [SampleTask] {
        tasks.filter { $0.status == "in_progress" }
    }

    private var doneTasks: [SampleTask] {
        tasks.filter { $0.status == "done" }
    }
}

struct SampleTask: Sendable {
    let title: String
    let priority: String
    let status: String
}

private let sampleTasks: [SampleTask] = [
    SampleTask(title: "Design landing page", priority: "high", status: "done"),
    SampleTask(title: "Implement auth flow", priority: "high", status: "in_progress"),
    SampleTask(title: "Write API docs", priority: "medium", status: "in_progress"),
    SampleTask(title: "Add dark mode", priority: "medium", status: "todo"),
    SampleTask(title: "Set up CI pipeline", priority: "low", status: "todo"),
    SampleTask(title: "Performance audit", priority: "medium", status: "todo"),
]
