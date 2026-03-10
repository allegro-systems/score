import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ScoreMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActionMacro.self,
        ComputedMacro.self,
        ContentInitMacro.self,
        StateMacro.self,
    ]
}
