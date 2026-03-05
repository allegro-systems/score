import Score

struct PostController: Controller {
    var base: String { "/api/posts" }

    var routes: [Route] {
        [
            Route(method: .get, handler: list),
            Route(method: .post, handler: create),
            Route(method: .get, path: "/:id", handler: show),
            Route(method: .delete, path: "/:id", handler: remove),
        ]
    }

    func list(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func create(_ request: RequestContext) async throws -> [String: String] {
        ["status": "created"]
    }

    func show(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func remove(_ request: RequestContext) async throws -> [String: String] {
        ["status": "deleted"]
    }
}
