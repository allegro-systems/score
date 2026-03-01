import Logging
import NIOCore
import NIOHTTP1
import NIOPosix
import ScoreCore
import ScoreRouter

/// A minimal HTTP/1.1 server that serves a Score application.
///
/// `Server` builds a ``RouteTable`` and page lookup dictionary from the
/// provided ``Application`` at initialisation time. Calling ``start()``
/// binds to the configured host and port and begins accepting connections.
///
/// ### Example
///
/// ```swift
/// let server = Server(application: MyApp())
/// try await server.start()
/// ```
public struct Server: Sendable {

    /// Configuration for the Score HTTP server.
    public struct Configuration: Sendable {

        /// The hostname to bind to.
        public var host: String

        /// The port to bind to.
        public var port: Int

        /// The runtime environment.
        public var environment: Environment

        /// The directory to serve static files from, or `nil` to disable
        /// static file serving. Requests to `/static/*` will be resolved
        /// against this directory.
        public var staticDirectory: String?

        /// Middleware applied to controller handler requests.
        public var middlewares: [HTTPMiddleware]

        /// Creates a server configuration.
        ///
        /// - Parameters:
        ///   - host: The hostname to bind to. Defaults to `"127.0.0.1"`.
        ///   - port: The port to bind to. Defaults to `8080`.
        ///   - environment: The runtime environment. Defaults to ``Environment/current``.
        ///   - staticDirectory: The static file directory, or `nil`.
        ///   - middlewares: Middleware to apply to controller requests.
        public init(
            host: String = "127.0.0.1",
            port: Int = 8080,
            environment: Environment = .current,
            staticDirectory: String? = nil,
            middlewares: [HTTPMiddleware] = []
        ) {
            self.host = host
            self.port = port
            self.environment = environment
            self.staticDirectory = staticDirectory
            self.middlewares = middlewares
        }
    }

    private let routeTable: RouteTable
    private let pages: [String: any Page]
    private let metadata: (any Metadata)?
    private let theme: (any Theme)?
    private let configuration: Configuration
    private let logger: Logger

    /// Creates a server for the given application.
    ///
    /// - Parameters:
    ///   - application: The Score application to serve.
    ///   - configuration: The server configuration. Defaults to standard values.
    public init(application: some Application, configuration: Configuration = Configuration()) {
        self.routeTable = RouteTable(application)
        var pages: [String: any Page] = [:]
        for page in application.pages {
            pages[type(of: page).path] = page
        }
        self.pages = pages
        self.metadata = application.metadata
        self.theme = application.theme
        self.configuration = configuration
        self.logger = Logger(label: "allegro.score.server")
    }

    /// Starts the HTTP server and blocks until it is shut down.
    ///
    /// - Throws: An error if the server fails to bind or encounters a
    ///   fatal networking error.
    public func start() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let routeTable = self.routeTable
        let pages = self.pages
        let metadata = self.metadata
        let theme = self.theme
        let staticDirectory = self.configuration.staticDirectory
        let middlewares = self.configuration.middlewares
        let environment = self.configuration.environment
        let logger = self.logger

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(
                        RequestHandler(
                            routeTable: routeTable,
                            pages: pages,
                            metadata: metadata,
                            theme: theme,
                            staticDirectory: staticDirectory,
                            middlewares: middlewares,
                            environment: environment,
                            logger: logger
                        )
                    )
                }
            }
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)

        let channel = try await bootstrap.bind(host: configuration.host, port: configuration.port).get()
        logger.info("Score server running on \(configuration.host):\(configuration.port) [\(configuration.environment.rawValue)]")

        try await channel.closeFuture.get()
        try await group.shutdownGracefully()
    }
}
