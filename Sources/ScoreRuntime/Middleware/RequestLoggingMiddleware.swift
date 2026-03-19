import Foundation
import HTTPTypes
import Logging

/// Logs every HTTP request with method, path, status code, and duration.
struct RequestLoggingMiddleware: Sendable {
    private let logger: Logger
    private let logHandler: (@Sendable (String) -> Void)?

    /// Log level from SCORE_LOG_LEVEL env var (default: info in production, debug in dev).
    static let resolvedLogLevel: Logger.Level = {
        if let env = ProcessInfo.processInfo.environment["SCORE_LOG_LEVEL"],
            let level = Logger.Level(rawValue: env.lowercased())
        {
            return level
        }
        return Environment.current == .development ? .debug : .info
    }()

    init(
        logger: Logger = Logger(label: "dev.allegro.score.request"),
        logHandler: (@Sendable (String) -> Void)? = nil
    ) {
        self.logger = logger
        self.logHandler = logHandler
    }

    func handle(
        method: HTTPRequest.Method,
        path: String,
        response: Response,
        duration: TimeInterval
    ) -> Response {
        let ms = Int(duration * 1000)
        let status = response.status.code
        let message = "\(method.rawValue) \(path) \(status) \(ms)ms"

        if let logHandler {
            logHandler(message)
        } else {
            let level: Logger.Level = status >= 500 ? .error : status >= 400 ? .warning : .info
            guard level >= Self.resolvedLogLevel else { return response }
            logger.log(level: level, "\(message)")
        }

        return response
    }
}
