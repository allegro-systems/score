import ArgumentParser

@main
struct ScoreCLI: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "score",
        abstract: "Score — the Swift web framework CLI.",
        version: "0.1.0",
        subcommands: [
            InitCommand.self,
            DevCommand.self,
            BuildCommand.self,
            DeployCommand.self,
        ]
    )
}
