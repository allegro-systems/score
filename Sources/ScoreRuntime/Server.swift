import NIOCore
import NIOPosix
import NIOHTTP1
import ScoreCore
import ScoreRouter

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
}
