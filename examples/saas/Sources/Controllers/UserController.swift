import Score

struct UserController: Controller {
    var base: String { "/api/users" }

    var routes: [Route] {
        [
            Route(method: .get, handler: list),
            Route(method: .get, path: "/:id", handler: show),
            Route(method: .put, path: "/:id", handler: update),
            Route(method: .delete, path: "/:id", handler: remove),
        ]
    }

    func list(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func show(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func update(_ request: RequestContext) async throws -> [String: String] {
        ["status": "updated"]
    }

    func remove(_ request: RequestContext) async throws -> [String: String] {
        ["status": "deleted"]
    }
}
