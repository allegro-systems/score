import ScoreRuntime

struct PostController: Controller {
    var base: String { "/api/posts" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/"),
            Route(method: .get, path: "/:slug"),
            Route(method: .post, path: "/"),
            Route(method: .put, path: "/:slug"),
            Route(method: .delete, path: "/:slug"),
        ]
    }
}
