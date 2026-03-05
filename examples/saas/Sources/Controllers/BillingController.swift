import Score

struct BillingController: Controller {
    var base: String { "/api/billing" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/subscription", handler: getSubscription),
            Route(method: .post, path: "/checkout", handler: checkout),
            Route(method: .post, path: "/webhook", handler: webhook),
        ]
    }

    func getSubscription(_ request: RequestContext) async throws -> [String: String] {
        ["status": "ok", "plan": "pro"]
    }

    func checkout(_ request: RequestContext) async throws -> [String: String] {
        ["status": "created"]
    }

    func webhook(_ request: RequestContext) async throws -> [String: String] {
        ["status": "received"]
    }
}
