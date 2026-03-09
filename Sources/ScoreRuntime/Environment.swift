import Foundation

/// The deployment environment of the Score application.
public enum Environment: String, Sendable, Equatable {

    /// Local development mode with verbose error pages and dev tools.
    case development

    /// Production mode with minimal error output and no dev tools.
    case production

    /// The current environment, determined by the `SCORE_ENV` environment variable.
    ///
    /// Defaults to `.development` if the variable is unset or unrecognised.
    public static var current: Environment {
        if let raw = ProcessInfo.processInfo.environment["SCORE_ENV"],
            let env = Environment(rawValue: raw)
        {
            return env
        }
        return .development
    }
}
