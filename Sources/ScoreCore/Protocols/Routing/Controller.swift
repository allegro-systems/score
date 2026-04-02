import HTTPTypes

// MARK: - @Controller Macro

/// Marks a struct as a ``Controller`` with automatic route and endpoint generation.
///
/// `@Controller` scans the struct for `@Route`-annotated functions and generates:
/// - ``Controller`` protocol conformance
/// - `var base: String` from the macro argument
/// - `var routes: [Route]` collecting all `@Route` handlers
/// - A `static var` ``Endpoint`` for each handler function (named after the function)
///
/// ### Usage
///
/// ```swift
/// @Controller("/api/posts")
/// struct PostController {
///     @Route(method: .get)
///     func listPosts(_ ctx: RequestContext) async throws -> Response { ... }
///
///     @Route(":postId", method: .get)
///     func getPost(_ ctx: RequestContext) async throws -> Response { ... }
///
///     @Route(":postId", method: .put)
///     func updatePost(_ ctx: RequestContext) async throws -> Response { ... }
/// }
/// ```
///
/// Generates:
/// ```swift
/// extension PostController: Controller {}
/// var base: String { "/api/posts" }
/// var routes: [Route] { ... }
/// static var listPosts: Endpoint { endpoint() }
/// static var getPost: Endpoint { endpoint(":postId") }
/// static var updatePost: Endpoint { endpoint(":postId") }
/// ```
@attached(member, names: arbitrary)
@attached(extension, conformances: Controller)
public macro Controller(_ base: String) = #externalMacro(module: "ScoreMacros", type: "ControllerMacro")

// MARK: - @Route Macro

/// Marks a function as an HTTP route handler within a ``Controller``.
///
/// `@Route` is a marker macro — it generates no code on its own but is read
/// by the ``Controller`` macro to build the route table and endpoint statics.
///
/// - Parameters:
///   - path: The sub-path relative to the controller's base. Defaults to root (`"/"`).
///   - method: The HTTP method this route handles.
@attached(peer)
public macro Route(_ path: String, method: RouteMethod) = #externalMacro(
    module: "ScoreMacros", type: "RouteMacro")

/// `@Route` at the controller root path.
@attached(peer)
public macro Route(method: RouteMethod) = #externalMacro(module: "ScoreMacros", type: "RouteMacro")

// MARK: - Controller Protocol

/// A protocol that groups a set of HTTP route handlers under a common base path.
///
/// `Controller` is the organisational unit for request handling in Score.
/// Each controller declares a `base` path prefix and a collection of `Route`
/// values that describe the HTTP method and sub-path for each endpoint it
/// manages.
///
/// Controllers are registered with an `Application` and collected at startup
/// to build the server's routing table.
///
/// Typical uses include:
/// - Grouping all endpoints for a single resource (e.g., `/users`)
/// - Separating API versioning concerns across different controller types
/// - Organising middleware-scoped route groups
///
/// ### Example
///
/// ```swift
/// struct UserController: Controller {
///     var routes: [Route] {
///         [
///             Route(method: .get, handler: listUsers),
///             Route(method: .post, handler: createUser),
///             Route(method: .get, path: ":id", handler: showUser),
///             Route(method: .put, path: ":id", handler: updateUser),
///             Route(method: .delete, path: ":id", handler: deleteUser),
///         ]
///     }
/// }
/// ```
public protocol Controller: Sendable {

    /// Creates a default instance of this controller.
    ///
    /// Required so ``endpoint(_:)`` can resolve the ``base`` path
    /// at compile time. All controllers are plain structs with no stored
    /// properties, so the memberwise initializer satisfies this.
    init()

    /// The base path prefix shared by all routes in this controller.
    ///
    /// All `Route` paths declared in `routes` are resolved relative to this
    /// value. For example, a `base` of `"/users"` combined with a route path
    /// of `"/:id"` produces the full path `"/users/:id"`.
    ///
    /// The value should begin with a leading `/`.
    var base: String { get }

    /// The collection of routes handled by this controller.
    ///
    /// Each `Route` pairs an HTTP method with a path segment that is appended
    /// to `base` to form the complete endpoint path.
    var routes: [Route] { get }
}

extension Controller {

    /// Creates an ``Endpoint`` relative to this controller's ``base`` path.
    ///
    /// Use this in `static` properties so `@Query` consumers can reference
    /// sub-paths without duplicating the base string:
    ///
    /// ```swift
    /// struct CommentController: Controller {
    ///     var base: String { "/api/comments" }
    ///
    ///     static var forPost: Endpoint { endpoint(":postId") }
    ///     static var all: Endpoint { endpoint() }
    ///
    ///     var routes: [Route] { ... }
    /// }
    /// ```
    ///
    /// - Parameter subpath: The path segment to append. Defaults to `"/"` (the base itself).
    /// - Returns: An ``Endpoint`` whose ``Endpoint/path`` is `base + subpath`, normalized.
    public static func endpoint(_ subpath: String = "/") -> Endpoint {
        let base = Self().base
        let combined = (base + "/" + subpath).normalized()
        return Endpoint(subpath: subpath.normalized(), path: combined)
    }
}

/// A type alias for the HTTP method used when defining a `Route`.
///
/// `RouteMethod` maps directly to `HTTPRequest.Method` from the `HTTPTypes`
/// package, providing standard values such as `.get`, `.post`, `.put`,
/// `.patch`, and `.delete`.
public typealias RouteMethod = HTTPRequest.Method

/// A value that describes a single HTTP endpoint by pairing a method with a path.
///
/// `Route` is the basic building block of a `Controller`'s routing table.
/// It combines an HTTP method with a path string to uniquely identify one
/// endpoint within a controller.
///
/// Path strings may include named parameters prefixed with `:` (for example,
/// `"/:id"`) whose values are extracted from the incoming request URL at
/// runtime.
///
/// ### Example
///
/// ```swift
/// let listRoute   = Route(method: .get, handler: listPosts)
/// let createRoute = Route(method: .post, handler: createPost)
/// let showRoute   = Route(method: .get, path: ":id", handler: showPost)
/// let updateRoute = Route(method: .patch, path: ":id", handler: updatePost)
/// let deleteRoute = Route(method: .delete, path: ":id", handler: deletePost)
/// ```
public struct Route: Sendable {

    /// The HTTP method this route responds to.
    ///
    /// Common values include `.get`, `.post`, `.put`, `.patch`, and `.delete`.
    public let method: RouteMethod

    /// The path for this route, relative to the owning controller's `base`.
    ///
    /// May include named path parameters prefixed with `:` (e.g., `"/:id"`).
    public let path: String

    /// The type-erased handler for this route.
    ///
    /// Handler typing is preserved at the call site through the generic
    /// `init(method:path:handler:)` initializer and erased here so heterogeneous
    /// handlers
    /// can coexist in a single `[Route]` collection.
    public let handler: (@Sendable (any Sendable) async throws -> any Sendable)?

    /// Creates a route with the specified HTTP method and path.
    ///
    /// - Parameters:
    ///   - method: The HTTP method this route handles.
    ///   - path: The path segment relative to the controller's `base`.
    public init(method: RouteMethod, path: String) {
        self.method = method
        self.path = path.normalized()
        self.handler = nil
    }

    /// Creates a route at the controller root path (`"/"`).
    ///
    /// - Parameter method: The HTTP method this route handles.
    public init(method: RouteMethod) {
        self.init(method: method, path: "/")
    }

    /// Creates a route with a typed request handler.
    ///
    /// - Parameters:
    ///   - method: The HTTP method this route handles.
    ///   - path: The path segment relative to the controller's `base`.
    ///   - handler: The handler invoked when this route matches. The handler's
    ///     request and response types are preserved by the generic signature
    ///     and type-erased for storage.
    public init<Request: Sendable, Response: Sendable>(
        method: RouteMethod,
        path: String,
        handler: @escaping @Sendable (Request) async throws -> Response
    ) {
        self.method = method
        self.path = path.normalized()
        self.handler = { request in
            guard let typedRequest = request as? Request else {
                throw HandlerInvocationError.requestTypeMismatch(
                    expected: String(describing: Request.self),
                    actual: String(describing: type(of: request))
                )
            }
            return try await handler(typedRequest)
        }
    }

    /// Creates a route with a typed request handler at the controller root path (`"/"`).
    ///
    /// - Parameters:
    ///   - method: The HTTP method this route handles.
    ///   - handler: The handler invoked when this route matches.
    public init<Request: Sendable, Response: Sendable>(
        method: RouteMethod,
        handler: @escaping @Sendable (Request) async throws -> Response
    ) {
        self.init(method: method, path: "/", handler: handler)
    }

    /// Errors raised while invoking a type-erased route handler.
    public enum HandlerInvocationError: Error, Sendable {

        /// The supplied request type did not match the route handler's expected type.
        ///
        /// - Parameters:
        ///   - expected: The request type expected by the route handler.
        ///   - actual: The actual runtime type supplied to the handler.
        case requestTypeMismatch(expected: String, actual: String)
    }
}
