import Foundation

/// Errors raised by the Score CLI.
enum CLIError: Error, CustomStringConvertible {

    /// The requested template does not exist.
    case unknownTemplate(String)

    /// The target directory already exists.
    case directoryExists(String)

    /// A file system operation failed.
    case fileSystemError(String)

    /// A child process exited with a non-zero code.
    case processFailure(command: String, exitCode: Int32, stderr: String)

    /// The Swift toolchain is not available.
    case toolchainNotFound

    /// A network operation failed (e.g. template clone).
    case networkError(String)

    var description: String {
        switch self {
        case .unknownTemplate(let name):
            "Unknown template '\(name)'. Run 'score init' to see available templates."
        case .directoryExists(let path):
            "Directory already exists: \(path)"
        case .fileSystemError(let detail):
            "File system error: \(detail)"
        case .processFailure(let command, let code, let stderr):
            "'\(command)' exited with code \(code):\n\(stderr)"
        case .toolchainNotFound:
            "Swift toolchain not found. Install Swift 6.2 or later."
        case .networkError(let detail):
            "Network error: \(detail)"
        }
    }
}
