import Score

struct APIController: Controller {
    var base: String { "/api" }

    var routes: [Route] {
        [
            Route(method: .get, path: "/status", handler: status)
        ]
    }

    func status(_ request: RequestContext) async throws -> StatusResponse {
        StatusResponse(status: "ok", version: "0.1.0")
    }
}

struct StatusResponse: Codable, Sendable {
    let status: String
    let version: String
}
