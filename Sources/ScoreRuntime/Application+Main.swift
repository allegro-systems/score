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

        if args.contains("--build") {
            try StaticSiteEmitter.emit(application: app)
            return
        }

        try StaticSiteEmitter.emit(application: app)

        var config = Server.Configuration()
        if let portIndex = args.firstIndex(of: "--port"),
            portIndex + 1 < args.count,
            let port = Int(args[portIndex + 1])
        {
            config = Server.Configuration(port: port)
        }

        let server = Server(application: app, configuration: config)
        try await server.run()
    }
}
