import Foundation

/// Writes tooling configuration files into a newly scaffolded project based
/// on the user's `--tasks`, `--hooks`, and `--env` selections.
struct ToolingConfigurator: Sendable {

    private init() {}

    static func configure(at directory: String, projectName: String, options: ToolingOptions) throws {
        let fm = FileManager.default

        // -- Task runner -------------------------------------------------------

        // Remove the default mise.toml that ships with the template — we'll
        // write the appropriate replacement (mise.toml or Makefile) below.
        let existingMise = "\(directory)/mise.toml"
        if fm.fileExists(atPath: existingMise) {
            try fm.removeItem(atPath: existingMise)
        }

        // Also remove fnox.toml from the template — the env provider step will
        // write the correct file (fnox.toml or .env).
        let existingFnox = "\(directory)/fnox.toml"
        if fm.fileExists(atPath: existingFnox) {
            try fm.removeItem(atPath: existingFnox)
        }

        switch options.tasks {
        case .mise:
            try writeMiseToml(to: directory, options: options)
        case .make:
            try writeMakefile(to: directory)
        }

        // -- Hook manager ------------------------------------------------------

        let existingHk = "\(directory)/hk.pkl"
        switch options.hooks {
        case .hk:
            // Template already ships with hk.pkl — keep it.
            // If it was accidentally removed, rewrite it.
            if !fm.fileExists(atPath: existingHk) {
                try writeHkPkl(to: directory)
            }
        case .none:
            if fm.fileExists(atPath: existingHk) {
                try fm.removeItem(atPath: existingHk)
            }
        }

        // -- Environment/secrets provider --------------------------------------

        switch options.env {
        case .fnox:
            try writeFnoxToml(to: directory)
        case .env:
            try writeDotEnv(to: directory)
            try appendToGitignore(at: directory, line: ".env")
        }
    }

    // MARK: - mise.toml

    private static func writeMiseToml(to directory: String, options: ToolingOptions) throws {
        var lines = [
            "[tools]",
            "swift = \"6.3\"",
        ]

        if options.hooks == .hk {
            lines.append("hk = { version = \"latest\", postinstall = \"hk install\" }")
        }

        if options.env == .fnox {
            lines.append("fnox = \"latest\"")
        }

        if options.env == .fnox {
            lines.append("")
            lines.append("[plugins]")
            lines.append("fnox-env = \"https://github.com/jdx/mise-env-fnox\"")
        }

        lines.append("")
        lines.append("[env]")
        if options.env == .fnox {
            lines.append("_.fnox-env = { tools = true }")
        }

        lines.append(contentsOf: miseTaskLines)

        let content = lines.joined(separator: "\n") + "\n"
        try content.write(toFile: "\(directory)/mise.toml", atomically: true, encoding: .utf8)
    }

    private static let miseTaskLines: [String] = [
        "",
        "# Dev Server",
        "[tasks.dev]",
        "description = \"Start the development server with hot reload\"",
        "raw = true",
        "usage = '''",
        "flag \"-p --port <port>\" help=\"Port for the dev server\" default=\"8080\"",
        "'''",
        "run = '''",
        "swift run score dev --port \"$usage_port\"",
        "'''",
        "",
        "# Build",
        "[tasks.build]",
        "description = \"Build the site for production\"",
        "usage = '''",
        "flag \"-v --verbose\" help=\"Show verbose build output\" default=\"false\"",
        "'''",
        "run = '''",
        "swift run ${usage_verbose:+-v} score build",
        "'''",
        "",
        "# Format & Lint",
        "[tasks.format]",
        "description = \"Format or lint source code\"",
        "usage = '''",
        "flag \"--check\" help=\"Lint instead of format\" default=\"false\"",
        "'''",
        "run = '''",
        "if [ \"${usage_check?}\" = \"true\" ]; then",
        "  swift format lint --recursive --strict Sources",
        "else",
        "  swift format --recursive -i Sources",
        "fi",
        "'''",
        "",
        "# Clean",
        "[tasks.clean]",
        "description = \"Remove build artifacts\"",
        "run = '''",
        "swift package clean",
        "rm -rf .score",
        "'''",
    ]

    // MARK: - Makefile

    private static func writeMakefile(to directory: String) throws {
        let content = """
        .PHONY: dev build format lint clean

        # Start the development server with hot reload
        dev:
        \tswift run score dev --port 8080

        # Build the site for production
        build:
        \tswift run score build

        # Format source code
        format:
        \tswift format --recursive -i Sources

        # Lint source code
        lint:
        \tswift format lint --recursive --strict Sources

        # Remove build artifacts
        clean:
        \tswift package clean
        \trm -rf .score

        """

        try content.write(toFile: "\(directory)/Makefile", atomically: true, encoding: .utf8)
    }

    // MARK: - hk.pkl

    private static func writeHkPkl(to directory: String) throws {
        let content = """
        amends "package://github.com/jdx/hk/releases/download/v1.39.0/hk@1.39.0#/Config.pkl"

        hooks {
          ["pre-commit"] {
            fix = true
            stash = "git"
            steps {
              ["swift-format"] {
                glob = List("*.swift")
                check = "swift format lint --strict {{files}}"
                fix = "swift format -i {{files}}"
              }
              ["swift-build"] {
                run = "swift build -c release -Xswiftc -warnings-as-errors"
              }
            }
          }
        }

        """

        try content.write(toFile: "\(directory)/hk.pkl", atomically: true, encoding: .utf8)
    }

    // MARK: - fnox.toml

    private static func writeFnoxToml(to directory: String) throws {
        let content = """
        # fnox — secret management for developers.
        # Docs: https://fnox.jdx.dev/
        #
        # Quick start:
        #   1. fnox keygen             — generate an age keypair (one-time)
        #   2. fnox set APP_SECRET … — encrypt and store a secret
        #   3. eval "$(fnox activate)" — load secrets into your shell
        #
        # Secrets are age-encrypted and safe to commit.

        [providers]
        age = { type = "age" }

        [secrets]
        APP_NAME = { default = "Score App" }
        # APP_SECRET = { provider = "age", value = "<run: fnox set APP_SECRET \\"your-value\\">" }

        """

        try content.write(toFile: "\(directory)/fnox.toml", atomically: true, encoding: .utf8)
    }

    // MARK: - .env

    private static func writeDotEnv(to directory: String) throws {
        let content = """
        # Environment variables for local development.
        # This file is git-ignored — never commit secrets.

        APP_NAME=MyApp
        # APP_SECRET=replace-me

        """

        try content.write(toFile: "\(directory)/.env", atomically: true, encoding: .utf8)
    }

    // MARK: - Helpers

    private static func appendToGitignore(at directory: String, line: String) throws {
        let gitignorePath = "\(directory)/.gitignore"
        let fm = FileManager.default

        if fm.fileExists(atPath: gitignorePath) {
            var content = try String(contentsOfFile: gitignorePath, encoding: .utf8)
            if !content.contains(line) {
                if !content.hasSuffix("\n") { content += "\n" }
                content += "\(line)\n"
                try content.write(toFile: gitignorePath, atomically: true, encoding: .utf8)
            }
        } else {
            try "\(line)\n".write(toFile: gitignorePath, atomically: true, encoding: .utf8)
        }
    }
}
