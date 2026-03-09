import ScoreRuntime

struct CartController: Controller {
    var base: String { "/api/cart" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/"),
            Route(method: .post, path: "/add"),
            Route(method: .post, path: "/remove"),
            Route(method: .post, path: "/update"),
        ]
    }
}
