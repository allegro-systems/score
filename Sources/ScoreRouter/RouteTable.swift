import HTTPTypes
import ScoreCore

/// A compiled lookup table that resolves incoming HTTP requests to route handlers.
///
/// `RouteTable` is built once at startup from an `Application`'s pages and
/// controllers. Internally it uses a trie (prefix tree) for O(path-length)
/// route resolution instead of linear scanning.
///
/// Pages are registered as GET routes first, followed by controller routes,
/// giving pages first-match-wins priority.
///
/// ### Supported Segment Patterns
///
/// - Literal: `"users"` matches exactly `"users"`
/// - Parameter: `":id"` matches any single segment and captures it
/// - Wildcard: `"*"` matches any single segment without capturing
/// - Catch-all: `"**"` matches one or more remaining segments, captured
///   as a `/`-joined string under the key `"**"`
///
/// ### Example
///
/// ```swift
/// let table = RouteTable(app)
/// let resolved = try table.resolve(method: .get, path: "/users/42")
/// let response = try await resolved.handler?(request)
/// ```
public struct RouteTable: Sendable {

    private let root: TrieNode

    /// Creates a route table from the given application.
    ///
    /// Pages are registered as GET routes first, followed by controller routes.
    ///
    /// - Parameter application: The application whose pages and controllers
    ///   define the routing surface.
    public init(_ application: some Application) {
        let builder = TrieNodeBuilder()

        for page in application.pages {
            let pattern = page.path
            let segments = RouteTable.splitSegments(pattern)
            let entry = RouteEntry(
                method: .get,
                pattern: pattern,
                segments: segments,
                handler: nil,
                isPage: true
            )
            builder.insert(segments: segments, index: 0, entry: entry)
        }

        let allControllers = application.controllers + application.plugins.flatMap(\.controllers)
        for controller in allControllers {
            for route in controller.routes {
                let pattern = RouteTable.combinePaths(controller.base, route.path)
                let segments = RouteTable.splitSegments(pattern)
                let entry = RouteEntry(
                    method: route.method,
                    pattern: pattern,
                    segments: segments,
                    handler: route.handler,
                    isPage: false
                )
                builder.insert(segments: segments, index: 0, entry: entry)
            }
        }

        self.root = TrieNode(builder)
    }

    /// Resolves an HTTP method and path to a matching route.
    ///
    /// - Parameters:
    ///   - method: The HTTP method of the incoming request.
    ///   - path: The URL path of the incoming request.
    /// - Returns: A `ResolvedRoute` containing the matched handler and
    ///   extracted path parameters.
    /// - Throws: ``RoutingError/notFound(path:)`` if no route matches the path,
    ///   or ``RoutingError/methodNotAllowed(path:allowed:)`` if the path matches
    ///   but not for the given method.
    public func resolve(method: HTTPRequest.Method, path: String) throws -> ResolvedRoute {
        let requestSegments = RouteTable.splitSegments(path)
        var matchedEntries: [RouteEntry] = []
        root.collectEntries(segments: requestSegments, index: 0, results: &matchedEntries)

        guard !matchedEntries.isEmpty else {
            throw RoutingError.notFound(path: path)
        }

        for entry in matchedEntries {
            if entry.method == method {
                let parameters = RouteTable.extractParameters(
                    pattern: entry.segments,
                    request: requestSegments
                )
                return ResolvedRoute(
                    method: entry.method,
                    pattern: entry.pattern,
                    parameters: parameters,
                    handler: entry.handler,
                    isPage: entry.isPage
                )
            }
        }

        let allowedMethods = matchedEntries.map(\.method)
        throw RoutingError.methodNotAllowed(path: path, allowed: allowedMethods)
    }

    static func splitSegments(_ path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }

    static func combinePaths(_ base: String, _ relative: String) -> String {
        let baseSegments = splitSegments(base)
        let relativeSegments = splitSegments(relative)
        let combined = (baseSegments + relativeSegments).joined(separator: "/")
        return combined.isEmpty ? "/" : "/\(combined)"
    }

    /// Checks whether a pattern matches a request and extracts parameters.
    ///
    /// Returns `nil` if the request does not match the pattern.
    static func match(pattern: [String], request: [String]) -> [String: String]? {
        var hasCatchAll = false
        for (i, seg) in pattern.enumerated() {
            if seg == "**" {
                hasCatchAll = true
                guard i < request.count else { return nil }
                break
            }
            guard i < request.count else { return nil }
            if seg == "*" || seg.hasPrefix(":") { continue }
            if seg != request[i] { return nil }
        }
        if !hasCatchAll && pattern.count != request.count { return nil }
        return extractParameters(pattern: pattern, request: request)
    }

    static func extractParameters(pattern: [String], request: [String]) -> [String: String] {
        var parameters: [String: String] = [:]

        for (i, patternSegment) in pattern.enumerated() {
            if patternSegment == "**" {
                guard i < request.count else { break }
                parameters["**"] = request[i...].joined(separator: "/")
                return parameters
            }

            guard i < request.count else { break }

            if patternSegment.hasPrefix(":") {
                parameters[String(patternSegment.dropFirst())] = request[i]
            }
        }

        return parameters
    }
}

/// A mutable builder used to construct the trie during ``RouteTable/init(_:)``.
///
/// After building, convert to an immutable ``TrieNode`` via ``TrieNode/init(_:)``.
private final class TrieNodeBuilder {

    var literalChildren: [String: TrieNodeBuilder] = [:]
    var paramChild: TrieNodeBuilder?
    var wildcardChild: TrieNodeBuilder?
    var catchAllEntries: [RouteEntry] = []
    var entries: [RouteEntry] = []

    init() {}

    func insert(segments: [String], index: Int, entry: RouteEntry) {
        guard index < segments.count else {
            entries.append(entry)
            return
        }

        let segment = segments[index]

        if segment == "**" {
            catchAllEntries.append(entry)
            return
        }

        if segment == "*" {
            if wildcardChild == nil {
                wildcardChild = TrieNodeBuilder()
            }
            wildcardChild?.insert(segments: segments, index: index + 1, entry: entry)
            return
        }

        if segment.hasPrefix(":") {
            if paramChild == nil {
                paramChild = TrieNodeBuilder()
            }
            paramChild?.insert(segments: segments, index: index + 1, entry: entry)
            return
        }

        if literalChildren[segment] == nil {
            literalChildren[segment] = TrieNodeBuilder()
        }
        literalChildren[segment]?.insert(segments: segments, index: index + 1, entry: entry)
    }
}

/// An immutable node in the routing trie.
///
/// Each node represents a path segment position and branches into children
/// keyed by segment type: literal strings, parameter captures, wildcards,
/// and catch-all patterns. The trie is built once at startup via
/// ``TrieNodeBuilder`` and only read during request resolution.
final class TrieNode: Sendable {

    fileprivate let literalChildren: [String: TrieNode]
    fileprivate let paramChild: TrieNode?
    fileprivate let wildcardChild: TrieNode?
    fileprivate let catchAllEntries: [RouteEntry]
    fileprivate let entries: [RouteEntry]

    fileprivate init(_ builder: TrieNodeBuilder) {
        self.literalChildren = builder.literalChildren.mapValues { TrieNode($0) }
        self.paramChild = builder.paramChild.map { TrieNode($0) }
        self.wildcardChild = builder.wildcardChild.map { TrieNode($0) }
        self.catchAllEntries = builder.catchAllEntries
        self.entries = builder.entries
    }

    func collectEntries(
        segments: [String],
        index: Int,
        results: inout [RouteEntry]
    ) {
        if index == segments.count {
            results.append(contentsOf: entries)
            return
        }

        let segment = segments[index]

        if let child = literalChildren[segment] {
            child.collectEntries(segments: segments, index: index + 1, results: &results)
        }

        if let child = paramChild {
            child.collectEntries(segments: segments, index: index + 1, results: &results)
        }

        if let child = wildcardChild {
            child.collectEntries(segments: segments, index: index + 1, results: &results)
        }

        if !catchAllEntries.isEmpty {
            results.append(contentsOf: catchAllEntries)
        }
    }
}
