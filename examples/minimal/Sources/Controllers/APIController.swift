import ScoreRuntime

struct APIController: Controller {
    var base: String { "/api" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/status")
        ]
    }
}
