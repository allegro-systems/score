import HTTPTypes
import ScoreCore
import Testing

@testable import ScoreRouter

// MARK: - Test helpers

struct StubPage: Page {
    static let path = "/"
    var body: some Node { EmptyNode() }
}

struct AboutPage: Page {
    static let path = "/about"
    var body: some Node { EmptyNode() }
}

struct UserController: Controller {
    let base = "/users"
    var routes: [Route] {
        [
            Route(method: .get),
            Route(method: .post),
            Route(method: .get, path: ":id"),
            Route(method: .put, path: ":id"),
            Route(method: .delete, path: ":id"),
        ]
    }
}

struct PostController: Controller {
    let base = "/posts"
    var routes: [Route] {
        [
            Route(method: .get),
            Route(method: .get, path: ":postId/comments/:commentId"),
        ]
    }
}

struct TestApp: Application {
    var pages: [any Page] { [StubPage(), AboutPage()] }
    var controllers: [any Controller] { [UserController(), PostController()] }
}

struct EmptyApp: Application {
    var pages: [any Page] { [] }
    var controllers: [any Controller] { [] }
}

struct PagesOnlyApp: Application {
    var pages: [any Page] { [StubPage(), AboutPage()] }
}

// MARK: - Segment splitting

@Test func splitSegmentsFromRoot() {
    #expect(RouteTable.splitSegments("/") == [])
}

@Test func splitSegmentsMultiple() {
    #expect(RouteTable.splitSegments("/users/42/posts") == ["users", "42", "posts"])
}

@Test func splitSegmentsTrailingSlash() {
    #expect(RouteTable.splitSegments("/users/") == ["users"])
}

// MARK: - Path combination

@Test func combinePathsRootRelative() {
    #expect(RouteTable.combinePaths("/users", "/") == "/users")
}

@Test func combinePathsSubpath() {
    #expect(RouteTable.combinePaths("/users", "/:id") == "/users/:id")
}

@Test func combinePathsNormalization() {
    #expect(RouteTable.combinePaths("/api/", "/v1/") == "/api/v1")
}

// MARK: - Segment matching

@Test func matchExactSegments() {
    let result = RouteTable.match(pattern: ["users"], request: ["users"])
    #expect(result == [:])
}

@Test func matchParameterSegments() {
    let result = RouteTable.match(pattern: ["users", ":id"], request: ["users", "42"])
    #expect(result == ["id": "42"])
}

@Test func matchFailsOnCountMismatch() {
    let result = RouteTable.match(pattern: ["users", ":id"], request: ["users"])
    #expect(result == nil)
}

@Test func matchFailsOnLiteralMismatch() {
    let result = RouteTable.match(pattern: ["users", "all"], request: ["users", "42"])
    #expect(result == nil)
}

// MARK: - Wildcard matching

@Test func matchSingleWildcard() {
    let result = RouteTable.match(pattern: ["files", "*", "info"], request: ["files", "readme", "info"])
    #expect(result == [:])
}

@Test func matchWildcardDoesNotCapture() {
    let result = RouteTable.match(pattern: ["files", "*"], request: ["files", "readme.txt"])
    #expect(result != nil)
    #expect(result?.isEmpty == true)
}

@Test func matchWildcardFailsOnMissing() {
    let result = RouteTable.match(pattern: ["files", "*"], request: ["files"])
    #expect(result == nil)
}

@Test func matchWildcardWithParameter() {
    let result = RouteTable.match(pattern: [":user", "*", "profile"], request: ["alice", "settings", "profile"])
    #expect(result == ["user": "alice"])
}

// MARK: - Catch-all matching

@Test func matchCatchAll() {
    let result = RouteTable.match(pattern: ["files", "**"], request: ["files", "docs", "readme.md"])
    #expect(result == ["**": "docs/readme.md"])
}

@Test func matchCatchAllSingleSegment() {
    let result = RouteTable.match(pattern: ["files", "**"], request: ["files", "readme.md"])
    #expect(result == ["**": "readme.md"])
}

@Test func matchCatchAllRequiresAtLeastOneSegment() {
    let result = RouteTable.match(pattern: ["files", "**"], request: ["files"])
    #expect(result == nil)
}

@Test func matchCatchAllWithPrefix() {
    let result = RouteTable.match(pattern: ["api", ":version", "**"], request: ["api", "v2", "users", "42", "posts"])
    #expect(result == ["version": "v2", "**": "users/42/posts"])
}

@Test func matchCatchAllManySegments() {
    let result = RouteTable.match(pattern: ["**"], request: ["a", "b", "c", "d"])
    #expect(result == ["**": "a/b/c/d"])
}

// MARK: - Route table construction

@Test func tableRegistersPageAsGetRoute() throws {
    let table = RouteTable(PagesOnlyApp())
    let resolved = try table.resolve(method: .get, path: "/about")
    #expect(resolved.isPage)
    #expect(resolved.method == .get)
    #expect(resolved.pattern == "/about")
}

@Test func tableRegistersControllerRoutes() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .post, path: "/users")
    #expect(!resolved.isPage)
    #expect(resolved.method == .post)
}

// MARK: - Resolution success

@Test func resolveExactMatch() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .get, path: "/users")
    #expect(resolved.pattern == "/users")
    #expect(resolved.parameters.isEmpty)
}

@Test func resolveParameterExtraction() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .get, path: "/users/42")
    #expect(resolved.parameters == ["id": "42"])
    #expect(resolved.pattern == "/users/:id")
}

@Test func resolveHandlerInvocation() async throws {
    struct HandlerController: Controller {
        let base = "/echo"
        var routes: [Route] {
            [Route(method: .post, handler: { (input: String) -> String in input.uppercased() })]
        }
    }
    struct HandlerApp: Application {
        var pages: [any Page] { [] }
        var controllers: [any Controller] { [HandlerController()] }
    }

    let table = RouteTable(HandlerApp())
    let resolved = try table.resolve(method: .post, path: "/echo")
    let response = try await resolved.handler?("hello") as? String
    #expect(response == "HELLO")
}

// MARK: - Resolution errors

@Test func resolveNotFound() {
    let table = RouteTable(TestApp())
    #expect(throws: RoutingError.self) {
        try table.resolve(method: .get, path: "/nonexistent")
    }
}

@Test func resolveMethodNotAllowed() {
    let table = RouteTable(TestApp())
    do {
        _ = try table.resolve(method: .patch, path: "/users")
        #expect(Bool(false), "Expected methodNotAllowed")
    } catch let error as RoutingError {
        if case .methodNotAllowed(let path, let allowed) = error {
            #expect(path == "/users")
            #expect(allowed.contains(.get))
            #expect(allowed.contains(.post))
        } else {
            #expect(Bool(false), "Expected methodNotAllowed, got \(error)")
        }
    } catch {
        #expect(Bool(false), "Unexpected error: \(error)")
    }
}

@Test func distinguishNotFoundFromMethodNotAllowed() {
    let table = RouteTable(TestApp())

    do {
        _ = try table.resolve(method: .get, path: "/nothing")
    } catch let error as RoutingError {
        #expect(error.status == .notFound)
    } catch {}

    do {
        _ = try table.resolve(method: .patch, path: "/users")
    } catch let error as RoutingError {
        #expect(error.status == .methodNotAllowed)
    } catch {}
}

// MARK: - Page vs Controller

@Test func isPageFlagCorrectness() throws {
    let table = RouteTable(TestApp())
    let page = try table.resolve(method: .get, path: "/about")
    #expect(page.isPage)
    let controller = try table.resolve(method: .post, path: "/users")
    #expect(!controller.isPage)
}

// MARK: - Edge cases

@Test func resolveRootPath() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .get, path: "/")
    #expect(resolved.isPage)
    #expect(resolved.pattern == "/")
}

@Test func resolveMultipleParameters() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .get, path: "/posts/7/comments/3")
    #expect(resolved.parameters == ["postId": "7", "commentId": "3"])
}

@Test func resolveTrailingSlashTolerance() throws {
    let table = RouteTable(TestApp())
    let resolved = try table.resolve(method: .get, path: "/users/")
    #expect(resolved.pattern == "/users")
}

@Test func emptyAppReturnsNotFound() {
    let table = RouteTable(EmptyApp())
    #expect(throws: RoutingError.self) {
        try table.resolve(method: .get, path: "/anything")
    }
}

// MARK: - Wildcard route resolution

@Test func resolveWildcardRoute() throws {
    struct WildcardController: Controller {
        let base = "/files"
        var routes: [Route] {
            [Route(method: .get, path: "*/info")]
        }
    }
    struct WildcardApp: Application {
        var pages: [any Page] { [] }
        var controllers: [any Controller] { [WildcardController()] }
    }

    let table = RouteTable(WildcardApp())
    let resolved = try table.resolve(method: .get, path: "/files/readme/info")
    #expect(resolved.parameters.isEmpty)
}

@Test func resolveCatchAllRoute() throws {
    struct CatchAllController: Controller {
        let base = "/docs"
        var routes: [Route] {
            [Route(method: .get, path: "**")]
        }
    }
    struct CatchAllApp: Application {
        var pages: [any Page] { [] }
        var controllers: [any Controller] { [CatchAllController()] }
    }

    let table = RouteTable(CatchAllApp())
    let resolved = try table.resolve(method: .get, path: "/docs/guide/getting-started")
    #expect(resolved.parameters == ["**": "guide/getting-started"])
}
