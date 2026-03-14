import NIOCore
import NIOHTTP1
import NIOPosix
import ScoreCore
import ScoreRouter
import ServiceLifecycle

/// A Score application server.
public struct Server: Sendable {

    /// Server configuration.
    public struct Configuration: Sendable {
        public let host: String
        public let port: Int
        public let environment: Environment

        public init(
            host: String = "127.0.0.1",
            port: Int = 8080,
            environment: Environment = .development
        ) {
            self.host = host
            self.port = port
            self.environment = environment
        }
    }

    private let application: any Application
    private let configuration: Configuration

    /// Creates a server for the given application.
    public init(
        application: some Application,
        configuration: Configuration = Configuration()
    ) {
        self.application = application
        self.configuration = configuration
    }

    /// Starts the server and begins accepting connections.
    ///
    /// Serves pre-built static files from the application's output directory
    /// and dispatches controller routes dynamically. Binds to the configured
    /// host and port, then serves until a termination signal (SIGINT or
    /// SIGTERM) is received.
    public func run() async throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let routeTable = RouteTable(application)
        let outputDir = application.outputDirectory

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(
                        RequestHandler(
                            outputDirectory: outputDir,
                            routeTable: routeTable
                        )
                    )
                }
            }
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 1)

        let channel = try await bootstrap.bind(
            host: configuration.host,
            port: configuration.port
        ).get()

        try await withGracefulShutdownHandler {
            try await channel.closeFuture.get()
        } onGracefulShutdown: {
            channel.close(promise: nil)
        }

        try await group.shutdownGracefully()
    }
}
