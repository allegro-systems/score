import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ScoreMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActionMacro.self
    ]
}
