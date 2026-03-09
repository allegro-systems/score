import ScoreRuntime

struct AuthController: Controller {
    var base: String { "/auth" }

    var routes: [Route] {
        [
            Route(method: .post, path: "/login"),
            Route(method: .post, path: "/logout"),
            Route(method: .post, path: "/signup"),
        ]
    }
}
