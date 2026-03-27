import ArgumentParser

/// Task runner choice for a new project.
enum TaskRunner: String, ExpressibleByArgument, CaseIterable, Sendable {
    case mise
    case make
}

/// Git hook manager choice for a new project.
enum HookManager: String, ExpressibleByArgument, CaseIterable, Sendable {
    case hk
    case none
}

/// Environment/secrets provider choice for a new project.
enum EnvProvider: String, ExpressibleByArgument, CaseIterable, Sendable {
    case fnox
    case env
}

/// Resolved tooling selections for project scaffolding.
struct ToolingOptions: Sendable {
    let tasks: TaskRunner
    let hooks: HookManager
    let env: EnvProvider
}
