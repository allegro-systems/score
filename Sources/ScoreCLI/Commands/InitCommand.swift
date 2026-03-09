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

    mutating func run() async throws {
        let projectName = name
        let selectedTemplate = try resolveTemplate()
        let destination = FileManager.default.currentDirectoryPath + "/\(projectName)"

        try await noora.progressStep(
            message: "Cloning \(selectedTemplate.directoryName) template"
        ) { _ in
            try TemplateCloner().clone(template: selectedTemplate, to: destination)
        }

        try await noora.progressStep(
            message: "Configuring project as \(projectName)"
        ) { _ in
            try ProjectNameRewriter().rewrite(at: destination, projectName: projectName)
            try SwiftFormatConfig.write(to: destination)
        }

        noora.success(
            .alert(
                "Created \(projectName) from the \(selectedTemplate.directoryName) template",
                takeaways: [
                    "cd \(projectName)",
                    "swift build",
                    "swift run \(projectName)",
                ]
            ))
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
