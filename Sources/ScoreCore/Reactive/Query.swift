/// A type-safe reference to a controller endpoint path.
///
/// Use the ``Controller/endpoint(_:)`` helper to build values relative
/// to a controller's base path without duplicating the string:
///
/// ```swift
/// struct CommentController: Controller {
///     var base: String { "/api/comments" }
///
///     static var forPost: Endpoint { endpoint(":postId") }
///
///     var routes: [Route] {
///         Route(method: .get, endpoint: Self.forPost, handler: listComments)
///     }
/// }
/// ```
///
/// Pass an `Endpoint` to `@Query` for type-safe sub-path queries:
///
/// ```swift
/// @Query(CommentController.forPost) var comments: [Comment]
/// ```
public struct Endpoint: Sendable {

    /// The sub-path relative to the controller's base (e.g. `"/:postId"`).
    ///
    /// Used by ``Route`` to define the route's path segment.
    public let subpath: String

    /// The fully resolved endpoint path (e.g. `"/api/comments/:postId"`).
    ///
    /// Used by `@Query` to know which URL to fetch from.
    public let path: String

    /// Creates an endpoint with the given sub-path and full path.
    public init(subpath: String, path: String) {
        self.subpath = subpath
        self.path = path
    }
}

/// Controls how a `@Query` synchronizes data between client and server.
///
/// - ``localFirst``: Data is cached in IndexedDB. CRUD operations update
///   the local cache immediately and sync to the server in the background.
///   Works offline — mutations queue and replay when connectivity returns.
/// - ``serverOnly``: Traditional fetch-based CRUD with no local caching.
///   Operations fail when offline.
public enum SyncMode: String, Sendable {
    /// IndexedDB cache + background sync (default).
    case localFirst
    /// Direct server fetch, no local caching.
    case serverOnly
}

/// Marks a stored property as a client-side data query with full CRUD.
///
/// `@Query` is an attached macro that transforms a stored property into
/// a reactive data source. On the client, it auto-fetches data from the
/// endpoint on mount and provides `.create()`, `.read()`, `.update()`,
/// and `.delete()` methods that auto-refetch after mutations.
///
/// ### Usage
///
/// ```swift
/// @Page("/")
/// struct HomePage {
///     @Query("/api/items") var items: [Item]
///
///     @Action func addItem() {
///         items.create(["title": input.title])
///     }
///
///     var body: some Node {
///         Paragraph { "Loading..." }
///             .visible(when: $items.isLoading)
///         for item in items {
///             Text { item.title }
///         }
///     }
/// }
/// ```
///
/// Optional polling:
///
/// ```swift
/// @Query("/api/items", poll: 5) var items: [Item]
/// ```
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: String) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Variant of `@Query` with automatic polling.
///
/// - Parameters:
///   - endpoint: The REST API endpoint URL.
///   - poll: Polling interval in seconds.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: String, poll: Int) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Variant of `@Query` with explicit sync mode.
///
/// - Parameters:
///   - endpoint: The REST API endpoint URL.
///   - sync: The synchronization strategy (`.localFirst` or `.serverOnly`).
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: String, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Variant of `@Query` with polling and explicit sync mode.
///
/// - Parameters:
///   - endpoint: The REST API endpoint URL.
///   - poll: Polling interval in seconds.
///   - sync: The synchronization strategy (`.localFirst` or `.serverOnly`).
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: String, poll: Int, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Type-safe variant of `@Query` that derives the endpoint from a ``Controller``'s `base` path.
///
/// ### Usage
///
/// ```swift
/// @Query(ItemsController.self) var items: [Item]
/// ```
///
/// The endpoint is resolved at init time via `ControllerType().base`.
/// - Parameter controller: The controller type whose `base` path is the endpoint.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ controller: any Controller.Type) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Type-safe `@Query` with polling.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ controller: any Controller.Type, poll: Int) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Type-safe `@Query` with explicit sync mode.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ controller: any Controller.Type, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Type-safe `@Query` with polling and explicit sync mode.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ controller: any Controller.Type, poll: Int, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Type-safe `@Query` that derives the endpoint from an ``Endpoint`` value.
///
/// Use this with ``Controller/endpoint(_:)`` to query sub-paths:
///
/// ```swift
/// @Query(CommentController.forPost) var comments: [Comment]
/// ```
///
/// - Parameter endpoint: The endpoint whose ``Endpoint/path`` is the query target.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: Endpoint) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// `@Query` with an ``Endpoint`` and polling.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: Endpoint, poll: Int) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// `@Query` with an ``Endpoint`` and explicit sync mode.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: Endpoint, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// `@Query` with an ``Endpoint``, polling, and explicit sync mode.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro Query(_ endpoint: Endpoint, poll: Int, sync: SyncMode) = #externalMacro(module: "ScoreMacros", type: "QueryMacro")

/// Metadata generated by the `@Query` macro for each query property.
///
/// The ``JSEmitter`` discovers `QueryDescriptor` instances via Mirror
/// to determine which properties should emit client-side fetch logic.
public struct QueryDescriptor: Sendable {

    /// The name of the query property.
    public let name: String

    /// The REST API endpoint URL.
    public let endpoint: String

    /// The polling interval in seconds, or `nil` for no polling.
    public let pollInterval: Int?

    /// The synchronization strategy for this query.
    public let syncMode: SyncMode

    /// Creates a query descriptor.
    ///
    /// - Parameters:
    ///   - name: The property name.
    ///   - endpoint: The REST API endpoint.
    ///   - pollInterval: Optional polling interval in seconds.
    ///   - syncMode: The sync strategy (defaults to `.localFirst`).
    public init(name: String, endpoint: String, pollInterval: Int? = nil, syncMode: SyncMode = .localFirst) {
        self.name = name
        self.endpoint = endpoint
        self.pollInterval = pollInterval
        self.syncMode = syncMode
    }
}

// MARK: - CRUD Stubs for @Action Type Checking

extension Array {

    /// Swift-side stub for `@Action` bodies. The actual implementation
    /// runs as JavaScript (`name_create(data)`) via the `@Query` signal.
    public func create(_ data: [String: Any]) {}

    /// Swift-side stub. JavaScript: `name_read()`.
    public func read() {}

    /// Swift-side stub. JavaScript: `name_update(id, data)`.
    public func update(_ id: Any, _ data: [String: Any]) {}

    /// Swift-side stub. JavaScript: `name_delete(id)`.
    public func delete(_ id: Any) {}

    /// Swift-side stub. JavaScript: `name_fetch()`.
    public func fetch() {}
}

/// A projection of a `@Query` property providing reactive sub-bindings
/// for loading state, error state, and CRUD operations.
///
/// Access via the `$` prefix on a query property:
///
/// ```swift
/// @Query("/api/items") var items: [Item]
///
/// // Loading indicator
/// Paragraph { "Loading..." }
///     .visible(when: $items.isLoading)
///
/// // Error display
/// Paragraph { "Error" }
///     .visible(when: $items.isFailed)
/// ```
public struct QueryProjection: Sendable {

    /// The name of the query property.
    public let name: String

    /// Creates a query projection.
    public init(name: String) {
        self.name = name
    }

    /// Reactive binding for the loading state.
    public var isLoading: ReactiveTextNode {
        ReactiveTextNode(name: "\(name)_isLoading", text: "")
    }

    /// Reactive binding for the failure state.
    public var isFailed: ReactiveTextNode {
        ReactiveTextNode(name: "\(name)_isFailed", text: "")
    }

    /// Reactive binding for the error message.
    public var error: ReactiveTextNode {
        ReactiveTextNode(name: "\(name)_error", text: "")
    }

    /// Reactive binding for whether unsynced mutations are pending.
    public var isSyncing: ReactiveTextNode {
        ReactiveTextNode(name: "\(name)_isSyncing", text: "")
    }

    /// Reactive binding for whether the client is offline.
    public var isOffline: ReactiveTextNode {
        ReactiveTextNode(name: "\(name)_isOffline", text: "")
    }
}
