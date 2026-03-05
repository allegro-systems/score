import Score

struct AuthController: Controller {
    var base: String { "/api/auth" }

    var routes: [Route] {
        [
            Route(method: .post, path: "/login", handler: login),
            Route(method: .post, path: "/logout", handler: logout),
        ]
    }

    func login(_ request: RequestContext) async throws -> [String: String] {
        ["status": "authenticated"]
    }

    func logout(_ request: RequestContext) async throws -> [String: String] {
        ["status": "logged_out"]
    }
}
