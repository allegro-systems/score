import ScoreRuntime

struct UserController: Controller {
    var base: String { "/api/user" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/profile"),
            Route(method: .post, path: "/update"),
        ]
    }
}
