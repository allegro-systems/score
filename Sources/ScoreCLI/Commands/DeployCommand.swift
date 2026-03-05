import ArgumentParser
import Noora

struct DeployCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "deploy",
        abstract: "Deploy to Stage."
    )

    mutating func run() throws {
        noora.warning(
            .alert("Stage deployment is not yet available", takeaway: "Stage hosting will be available in a future release")
        )
    }
}
