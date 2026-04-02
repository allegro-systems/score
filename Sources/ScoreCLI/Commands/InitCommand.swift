import ArgumentParser
import Foundation
import Noora

struct InitCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a new Score project from a template."
    )

    @Argument(help: "The project name.")
    var name: String

    @Option(name: .long, help: "Template to use. Run without this flag for an interactive picker.")
    var template: String?

    @Option(name: .long, help: "Task runner: mise (default) or make.")
    var tasks: TaskRunner = .mise

    @Option(name: .long, help: "Git hook manager: hk (default) or none.")
    var hooks: HookManager = .hk

    @Option(name: .long, help: "Environment/secrets provider: fnox (default) or env.")
    var env: EnvProvider = .fnox

    mutating func run() async throws {
        let projectName = name
        let selectedTemplate = try resolveTemplate()
        let destination = FileManager.default.currentDirectoryPath + "/\(projectName)"
        let tooling = ToolingOptions(tasks: tasks, hooks: hooks, env: env)

        try await noora.progressStep(
            message: "Cloning \(selectedTemplate.directoryName) template"
        ) { _ in
            try TemplateCloner().clone(template: selectedTemplate, to: destination)
        }

        try await noora.progressStep(
            message: "Configuring project as \(projectName)"
        ) { _ in
            try ProjectNameRewriter().rewrite(
                at: destination, projectName: projectName, isPlugin: selectedTemplate.isPlugin)
            try SwiftFormatConfig.write(to: destination)
        }

        try await noora.progressStep(
            message: "Configuring tooling"
        ) { _ in
            try ToolingConfigurator.configure(at: destination, projectName: projectName, options: tooling)
        }

        var takeaways: [TerminalText] = [
            "cd \(projectName)",
            "swift build",
            "swift run \(projectName)",
        ]

        if tooling.tasks == .mise {
            takeaways.append("mise install — to set up tool versions and hooks")
        }

        noora.success(
            .alert(
                "Created \(projectName) from the \(selectedTemplate.directoryName) template",
                takeaways: takeaways
            ))

        if tooling.tasks == .make {
            noora.warning(
                .alert(
                    "You selected make as your task runner — tool versions (Swift, hk, fnox) will require manual management",
                    takeaway: "mise auto-installs pinned tool versions per-project — consider switching back with --tasks mise"
                ))
        }
    }

    private func resolveTemplate() throws -> Template {
        if let templateName = template {
            guard let resolved = Template(rawValue: templateName) else {
                throw CLIError.unknownTemplate(templateName)
            }
            return resolved
        }

        let selected: Template = noora.singleChoicePrompt(
            title: "Project Template",
            question: "Which template would you like to use?",
            description: "Each template is a full, running Score app"
        )
        return selected
    }
}
