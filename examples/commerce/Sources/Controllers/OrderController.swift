import ScoreRuntime

struct OrderController: Controller {
    var base: String { "/api/orders" }

    var routes: [Route] {
        [
            Route(method: .post, path: "/place"),
            Route(method: .get, path: "/:id"),
        ]
    }
}
