import Foundation
import ScoreCore

extension Application {

    /// Entry point for `@main`-annotated Score applications.
    ///
    /// When an `Application` conformer is marked with `@main`, Swift calls
    /// this method automatically.
    ///
    /// - If the `--build` flag is present, the static site is emitted to the
    ///   application's `outputDirectory` and the process exits.
    /// - Otherwise a `Server` is started and begins listening for requests.
    ///
    /// ### Usage
    ///
    /// ```swift
    /// @main
    /// struct MyApp: Application {
    ///     var pages: [any Page] { [HomePage()] }
    /// }
    /// ```
    public static func main() async throws {
        let app = Self()
        let args = ProcessInfo.processInfo.arguments

        // --manifest: Print compiled-in metadata + routes to stdout, exit.
        // Used by stage-manager at deploy time to discover app capabilities.
        if args.contains("--manifest") {
            try ManifestEmitter.emit(application: app)
            return
        }

        if args.contains("--build") {
            try StaticSiteEmitter.emit(application: app)
            return
        }

        // --listen <socket>: Bind to a Unix socket and accept HTTP requests.
        // Production mode inside Stage — stays alive until SIGTERM.
        if let listenIndex = args.firstIndex(of: "--listen"),
            listenIndex + 1 < args.count
        {
            let socketPath = args[listenIndex + 1]
            let server = Server(
                application: app,
                configuration: .init(socketPath: socketPath, environment: .production)
            )
            try await server.run()
            return
        }

        try StaticSiteEmitter.emit(application: app)

        if #available(macOS 26.2, iOS 26.2, watchOS 26.2, tvOS 26.2, visionOS 26.2, *) {
            var config = Server.Configuration()
            if let portIndex = args.firstIndex(of: "--port"),
                portIndex + 1 < args.count,
                let port = Int(args[portIndex + 1])
            {
                config = Server.Configuration(port: port)
            }

            let server = Server(application: app, configuration: config)
            try await server.run()
        } else {
            fatalError("Score development server requires macOS 26.2 or later")
        }
    }
}
