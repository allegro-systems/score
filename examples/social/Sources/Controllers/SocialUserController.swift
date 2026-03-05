import Score

struct SocialUserController: Controller {
    var base: String { "/api/users" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/:id", handler: show),
            Route(method: .put, path: "/:id", handler: update),
        ]
    }

    func show(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok"]
    }

    func update(_ request: RequestContext) async throws -> [String: String] {
        ["status": "updated"]
    }
}
