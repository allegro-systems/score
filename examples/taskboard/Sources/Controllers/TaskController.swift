import Score

struct TaskController: Controller {
    var base: String { "/api/tasks" }

    var routes: [Route] {
        [
            Route(method: .get, handler: list),
            Route(method: .post, handler: create),
            Route(method: .put, path: "/:id", handler: update),
            Route(method: .delete, path: "/:id", handler: remove),
            Route(method: .patch, path: "/:id/status", handler: updateStatus),
        ]
    }

    func list(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func create(_ request: RequestContext) async throws -> [String: String] {
        ["status": "created"]
    }

    func update(_ request: RequestContext) async throws -> [String: String] {
        ["status": "updated"]
    }

    func remove(_ request: RequestContext) async throws -> [String: String] {
        ["status": "deleted"]
    }

    func updateStatus(_ request: RequestContext) async throws -> [String: String] {
        ["status": "updated"]
    }
}
